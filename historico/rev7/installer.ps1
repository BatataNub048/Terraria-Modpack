#requires -Version 5.1
[CmdletBinding()]
param(
    [ValidateSet('Menu','Install','Download','Verify','Activate','Restore','List')][string]$Mode='Menu',
    [ValidateRange(1,6)][int]$Stage=5,
    [string]$Optional='',
    [string]$SavePath='',
    [string]$TmlPath='',
    [string]$CachePath='',
    [string]$BackupPath='',
    [switch]$Offline,
    [switch]$SkipConfig,
    [switch]$BackupLocalConflicts
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$ProgressPreference='SilentlyContinue'
Import-Module (Join-Path $PSScriptRoot 'lib\Pack.psm1') -Force
$manifest=Read-PackJson (Join-Path $PSScriptRoot 'manifest.lock.json')
$interactiveMenu=($Mode -eq 'Menu')
if (-not $SavePath) { $SavePath=Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'My Games\Terraria\tModLoader' }
if ($Mode -eq 'Menu') {
    Write-Host 'TERRARIA - FOUR CONTENT MODS / revision 7 / tModLoader 2026.9.3.1 / audited 2026-11-03'
    Write-Host ('Package folder: '+$PSScriptRoot)
    Write-Host ('Destination for THIS Windows user: '+$SavePath)
    Write-Host 'Ao instalar/verificar, informe a pasta do JOGO. Mods/saves continuam no destino acima.'
    Write-Host '1 Install integrated pack (48 Workshop mods + local worldgen fix; stage 5)'
    Write-Host '2 Download and verify only (no game required)'
    Write-Host '3 Verify installed pack'
    Write-Host '4 Activate a testing stage using installed files'
    Write-Host '5 Restore a previous installation transaction'
    Write-Host '6 Show mod list'
    Write-Host '7 Install + back up conflicting local mod copies (preserves worlds/players)'
    Write-Host '0 Exit'
    $choice=Read-Host 'Choose'
    switch($choice) {
        '1' {$Mode='Install'}
        '2' {$Mode='Download'}
        '3' {$Mode='Verify'}
        '4' {$Mode='Activate'; $stageText=Read-Host 'Stage (1 content, 2 Fargo, 3 integrations, 4 storage/shops, 5 QoL)'; if ($stageText -notmatch '^[1-5]$') { throw 'Invalid stage' }; $Stage=[int]$stageText}
        '5' {$Mode='Restore'; $BackupPath=Read-Host 'Paste the backup folder path (without quotes)'}
        '6' {$Mode='List'}
        '7' {$Mode='Install'; $BackupLocalConflicts=$true}
        '0' {exit 0}
        default {throw 'Invalid menu option'}
    }
}
if ($BackupLocalConflicts -and $Mode -ne 'Install') { throw '-BackupLocalConflicts is only supported with Install.' }
$groups=@($Optional.Split(',') | ForEach-Object {$_.Trim().ToLowerInvariant()} | Where-Object {$_})
foreach($group in $groups) { if ($group -notin @('extras','wings','performance')) { throw "Unknown optional group: $group" } }
if ('performance' -in $groups -and $Stage -ne 6) { throw 'Performance experiment requires -Stage 6 -Optional performance' }
$selected=@(Get-PackSelection $manifest $Stage $groups)
if ($Mode -eq 'List') { $manifest.mods | Select-Object title,version,workshopId,stage,optionalGroup | Format-Table -AutoSize; exit 0 }
if (-not $CachePath) { $CachePath=Join-Path $PSScriptRoot 'cache' }
$SavePath=[IO.Path]::GetFullPath($SavePath); $CachePath=[IO.Path]::GetFullPath($CachePath)
$runId=(Get-Date -Format 'yyyyMMdd-HHmmss')+'-'+[guid]::NewGuid().ToString('N').Substring(0,8)
$reportPath=Join-Path $PSScriptRoot ('reports\'+$runId)
[IO.Directory]::CreateDirectory($reportPath) | Out-Null
$report=[ordered]@{installerRevision=7;auditDate=$manifest.auditDate;runId=$runId;mode=$Mode;stage=$Stage;optionalGroups=$groups;savePath=$SavePath;packagePath=$PSScriptRoot;tmlPath=$null;status='Running';targetTml=$manifest.targetTml;actualTml=$null;backup=$null;archivedLocal=@();gameplay='NOT_TESTED_BY_INSTALLER';error=$null;items=@()}
foreach($m in $manifest.mods) {
    $isSelected=$m.name -in $selected.name
    $report.items += [pscustomobject]@{name=$m.name;workshopId=$m.workshopId;expectedVersion=$m.version;selected=$isSelected;optional=[bool]$m.optionalGroup;download=if($isSelected){'NotAttempted'}else{'OptionalOrLaterStage'};integrity='NotVerified';copied='NotCopied';dependency='NotVerified';note=''}
}
$exitCode=0; $runLock=$null; $targetLock=$null
try {
    # Process-held file locks are released even if PowerShell is terminated.
    $runLock=[IO.File]::Open((Join-Path $PSScriptRoot '.installer.lock'),[IO.FileMode]::OpenOrCreate,[IO.FileAccess]::ReadWrite,[IO.FileShare]::None)
    if ($Mode -eq 'Restore') {
        Assert-PackGameClosed
        if (-not $BackupPath) { throw 'Specify -BackupPath with the exact backup directory from the installation report.' }
        $restoreJournal=Read-PackJson (Join-Path $BackupPath 'transaction.json')
        $restoreRoot=[IO.Path]::GetFullPath($restoreJournal.savePath)
        $SavePath=$restoreRoot; $report.savePath=$restoreRoot
        $targetLock=[IO.File]::Open((Get-PackPath $restoreRoot '.terraria-pack.lock'),[IO.FileMode]::OpenOrCreate,[IO.FileAccess]::ReadWrite,[IO.FileShare]::None)
        Restore-PackTransaction $BackupPath
        $report.status='Restored'; $report.backup=$BackupPath
    } else {
        $targetVersion=[version]$manifest.targetTml
        $localConflicts=@()
        if ($Mode -ne 'Download') {
            Assert-PackGameClosed
            if ($interactiveMenu -and -not $TmlPath) { $TmlPath=Read-PackTmlPath $targetVersion }
            $tml=Get-PackTml $TmlPath
            $report.tmlPath=$tml.Path
            $report.actualTml=$tml.ProductVersion
            if ($tml.Version -ne $targetVersion) { throw "This pack was audited on tModLoader $targetVersion. Found $($tml.Version). Use that version or re-audit before installing; no automatic downgrade." }
            Write-Host ('Pasta do JOGO: '+$tml.Path)
            Write-Host ('Pasta dos MODS e SAVES: '+$SavePath)
            [IO.Directory]::CreateDirectory($SavePath) | Out-Null
            $targetLock=[IO.File]::Open((Get-PackPath $SavePath '.terraria-pack.lock'),[IO.FileMode]::OpenOrCreate,[IO.FileAccess]::ReadWrite,[IO.FileShare]::None)
            $localConflicts=@(Test-PackLocalDuplicates $SavePath $selected -AllowLocalConflicts:$BackupLocalConflicts)
            foreach($conflict in $localConflicts) { Write-Host ('Will back up conflicting local file after downloads validate: '+$conflict.Path) }
        }
        $infos=@(); $errors=@()
        if ($Mode -in @('Install','Download')) {
            $receipts=$null
            if (-not $Offline) { $receipts=Invoke-PackDownloads @($selected | Where-Object source -eq 'workshop') $CachePath $reportPath }
            foreach($m in $selected) {
                $row=$report.items | Where-Object name -eq $m.name
                $itemPath=Join-Path $CachePath ('steamcmd\steamapps\workshop\content\1281930\'+$m.workshopId)
                if ($m.source -eq 'bundled') {$row.download='BundledLocalBuild'}
                elseif ($Offline) {$row.download='ExistingCache'}
                elseif ($receipts.Receipts[$m.workshopId]) {$row.download='Downloaded'}
                else {$row.download='MissingOrFailed'; $errors += "No Steam success receipt for $($m.name)"}
                try {
                    if ($m.source -eq 'bundled') { $info=Test-PackMod (Get-PackPath $PSScriptRoot ('bundled\'+$m.name+'.tmod')) $m $targetVersion }
                    else { $info=Find-PackMod $itemPath $m $targetVersion }
                    $infos += $info; $row.integrity='SHA256_AND_TMOD_OK'
                    if ($receipts -and $receipts.ExitCode -ne 0) { $row.note="SteamCMD exit $($receipts.ExitCode); item receipt and bytes verified separately" }
                } catch { $row.integrity='Failed'; $row.note=$_.Exception.Message; $errors += $row.note }
            }
        } else {
            foreach($m in $selected) {
                $row=$report.items | Where-Object name -eq $m.name
                try {
                    $path=Get-PackPath $SavePath ('Mods\'+$m.name+'.tmod')
                    $infos += Test-PackMod $path $m $targetVersion
                    $row.integrity='SHA256_AND_TMOD_OK'; $row.copied='InstalledFileVerified'
                } catch { $row.integrity='Failed'; $row.note=$_.Exception.Message; $errors += $row.note }
            }
        }
        if ($errors.Count) { throw ($errors -join "`n") }
        Test-PackDependencies $infos $selected
        foreach($row in $report.items | Where-Object selected) {$row.dependency='RequiredAndPresentWeakVersionsOK'}
        if ($Mode -eq 'Verify') {
            $enabled=@(Read-PackJson (Get-PackPath $SavePath 'Mods\enabled.json'))
            $missing=@($selected.name | Where-Object {$_ -notin $enabled})
            $extra=@($enabled | Where-Object {$_ -notin $selected.name})
            if ($missing.Count -or $extra.Count) { throw "Enabled list differs from selected profile. Missing: $($missing -join ', '). Extra/unreviewed: $($extra -join ', '). Select the matching stage/options or use Activate." }
            $report.status='InstalledFilesVerified_GameplayUnverified'
        } elseif ($Mode -eq 'Download') {
            $report.status='DownloadsVerified_NotInstalled'
        } else {
            $changes=@()
            if ($Mode -eq 'Install') {
                foreach($info in $infos) {
                    $relative='Mods\'+$info.Name+'.tmod'; $target=Get-PackPath $SavePath $relative
                    $row=$report.items | Where-Object name -eq $info.Name
                    if ((Test-Path -LiteralPath $target) -and (Get-PackHash $target) -eq $info.Sha256) { $row.copied='AlreadyIdentical' }
                    else { $changes += [pscustomobject]@{relative=$relative;source=$info.Path} }
                }
                foreach($conflict in $localConflicts) {
                    $relative='Mods\'+[IO.Path]::GetFileName($conflict.Path)
                    $changes += [pscustomobject]@{relative=$relative;action='archive';expectedHash=$conflict.Sha256}
                }
            }
            $staging=Join-Path $reportPath 'prepared'; [IO.Directory]::CreateDirectory($staging) | Out-Null
            if (-not $SkipConfig -and $Mode -eq 'Install') {
                $presets=Read-PackJson (Join-Path $PSScriptRoot 'config-preset.json')
                foreach($preset in $presets) {
                    if ($preset.mod -notin $selected.name) {continue}
                    $relative='ModConfigs\'+$preset.file; $target=Get-PackPath $SavePath $relative
                    $config=[pscustomobject]@{}
                    if (Test-Path -LiteralPath $target) { $config=Read-PackJson $target; if ($config -isnot [pscustomobject]) {throw "Config must be a JSON object: $target"} }
                    foreach($property in $preset.values.PSObject.Properties) { $config | Add-Member -NotePropertyName $property.Name -NotePropertyValue $property.Value -Force }
                    $source=Join-Path $staging $preset.file; Write-PackJson $source $config
                    if (-not (Test-Path -LiteralPath $target) -or (Get-PackHash $target) -ne (Get-PackHash $source)) { $changes += [pscustomobject]@{relative=$relative;source=$source} }
                }
            }
            # Enabled list is changed last, after every payload/config is ready.
            $enabledSource=Join-Path $staging 'enabled.json'
            Write-PackJson $enabledSource @($selected.name)
            $enabledTarget=Get-PackPath $SavePath 'Mods\enabled.json'
            if (-not (Test-Path -LiteralPath $enabledTarget) -or (Get-PackHash $enabledTarget) -ne (Get-PackHash $enabledSource)) { $changes += [pscustomobject]@{relative='Mods\enabled.json';source=$enabledSource} }
            if ($changes.Count) { $report.backup=New-PackTransaction $SavePath (Join-Path $PSScriptRoot 'backups') $changes }
            foreach($conflict in $localConflicts) {
                $report.archivedLocal += [pscustomobject]@{name=$conflict.Name;originalPath=$conflict.Path;sha256=$conflict.Sha256;backupRelative=('files\Mods\'+[IO.Path]::GetFileName($conflict.Path))}
            }
            foreach($info in $infos) {
                $target=Get-PackPath $SavePath ('Mods\'+$info.Name+'.tmod')
                if ((Get-PackHash $target) -ne $info.Sha256) {throw "Post-copy mismatch: $($info.Name)"}
                $row=$report.items | Where-Object name -eq $info.Name
                if ($row.copied -eq 'NotCopied') {$row.copied='CopiedAndVerified'}
            }
            $report.status=if($Mode -eq 'Activate'){'StageActivated_GameplayUnverified'}else{'InstalledAndVerified_GameplayUnverified'}
        }
    }
} catch {
    $exitCode=1; $report.status='Failed'; $report.error=$_.Exception.Message
    if ($_.Exception -is [OperationCanceledException]) { $exitCode=2; $report.status='Cancelled' }
    Write-Host ('ERROR: '+$report.error) -ForegroundColor Red
} finally {
    if ($targetLock) {$targetLock.Dispose()}; if($runLock){$runLock.Dispose()}
    Write-PackJson (Join-Path $reportPath 'report.json') $report
    $report.items | Export-Csv -LiteralPath (Join-Path $reportPath 'items.csv') -NoTypeInformation -Encoding UTF8
    $summary=@("Status: $($report.status)","Mode: $Mode / Stage: $Stage","tModLoader installation: $($report.tmlPath)","Destination: $SavePath","Backup: $($report.backup)","Conflicting local files archived: $($report.archivedLocal.Count)","Game test: $($report.gameplay)","Error: $($report.error)","Details: items.csv and report.json")
    [IO.File]::WriteAllLines((Join-Path $reportPath 'summary.txt'),$summary,[Text.UTF8Encoding]::new($false))
    Write-Host ($summary -join "`n")
    Write-Host "Report: $reportPath"
}
exit $exitCode
