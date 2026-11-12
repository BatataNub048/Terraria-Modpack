Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
if (-not ('PackTmodReader' -as [type])) { Add-Type -Path (Join-Path $PSScriptRoot 'TmodInspector.cs') }

function Write-PackJson($Path, $Value) {
    $parent = Split-Path -Parent $Path
    [IO.Directory]::CreateDirectory($parent) | Out-Null
    $text = ConvertTo-Json -InputObject $Value -Depth 40
    [IO.File]::WriteAllText($Path, $text, [Text.UTF8Encoding]::new($false))
}
function Read-PackJson($Path) {
    $parsed=Get-Content -LiteralPath $Path -Raw -Encoding UTF8 | ConvertFrom-Json
    return $parsed
}
function Get-PackHash($Path) { [PackTmodReader]::FileSha256($Path) }
function Get-PackPath($Root, $Relative) {
    $rootPath = [IO.Path]::GetFullPath($Root).TrimEnd('\','/') + [IO.Path]::DirectorySeparatorChar
    $path = [IO.Path]::GetFullPath((Join-Path $rootPath $Relative))
    if (-not $path.StartsWith($rootPath, [StringComparison]::OrdinalIgnoreCase)) { throw "Path outside intended directory: $Relative" }
    # A junction inside the destination could redirect a write outside it.
    $cursor = Split-Path -Parent $path
    while ($cursor -and $cursor.Length -ge $rootPath.TrimEnd('\').Length) {
        if (Test-Path -LiteralPath $cursor) {
            if ((Get-Item -LiteralPath $cursor -Force).Attributes -band [IO.FileAttributes]::ReparsePoint) { throw "Junction/symlink not supported in destination: $cursor" }
        }
        $next = Split-Path -Parent $cursor
        if ($next -eq $cursor) { break }; $cursor = $next
    }
    if ((Test-Path -LiteralPath $path) -and ((Get-Item -LiteralPath $path -Force).Attributes -band [IO.FileAttributes]::ReparsePoint)) { throw "Symlink file not supported: $path" }
    return $path
}
function Get-PackSelection($Manifest, [int]$Stage, [string[]]$OptionalGroups) {
    if ($Manifest.schema -ne 1) { throw 'Unsupported manifest schema' }
    $selected = @($Manifest.mods | Where-Object { $_.stage -le $Stage -and (-not $_.optionalGroup -or $_.optionalGroup -in $OptionalGroups) })
    if (-not $selected.Count) { throw 'Empty mod selection' }
    foreach ($property in @('name','workshopId')) {
        if (@($Manifest.mods | Group-Object $property | Where-Object Count -gt 1).Count) { throw "Duplicate $property in manifest" }
    }
    foreach ($m in $Manifest.mods) {
        if ($m.source -notin @('workshop','bundled') -or $m.name -notmatch '^[A-Za-z][A-Za-z0-9_]*$' -or $m.sha256 -notmatch '^[a-f0-9]{64}$') { throw 'Invalid manifest entry' }
        if (($m.source -eq 'workshop' -and $m.workshopId -notmatch '^\d+$') -or ($m.source -eq 'bundled' -and $m.workshopId -cne ('local:'+$m.name))) { throw 'Invalid source identifier' }
        foreach ($dependency in @($m.required) + @($m.additionalRequired)) {
            $depName = ($dependency -split '@')[0]
            if ($m -in $selected -and $depName -notin $selected.name) { throw "Missing selected dependency: $($m.name) -> $depName" }
        }
    }
    return $selected
}
function Test-PackMod($Path, $Expected, [version]$TargetTml) {
    $actual = [PackTmodReader]::Read($Path)
    if ($actual.Name -cne $Expected.name) { throw "Wrong internal name: expected $($Expected.name), found $($actual.Name)" }
    if ([version]$actual.BuildTml -lt [version]'2023.6' -or [version]$actual.BuildTml -gt $TargetTml) { throw "Unsupported tModLoader build $($actual.BuildTml) for $($actual.Name)" }
    if ($actual.Version -ne $Expected.version -or $actual.Sha256 -ne $Expected.sha256) { throw "VERSION DRIFT: $($actual.Name) $($actual.Version). Download differs from audited lock. Keep the previous install and re-audit." }
    if (@(Compare-Object @($actual.Required | Sort-Object) @($Expected.required | Sort-Object)).Count) { throw "Dependency metadata differs from manifest: $($actual.Name)" }
    return $actual
}
function Find-PackMod($ItemPath, $Expected, [version]$TargetTml) {
    $candidates = @(Get-ChildItem -LiteralPath $ItemPath -Filter '*.tmod' -Recurse -File -ErrorAction SilentlyContinue)
    if (-not $candidates.Count) { throw "MISSING: Workshop $($Expected.workshopId) has no .tmod files" }
    $matching = @(); $errors = @()
    foreach ($candidate in $candidates) {
        try {
            $actual = [PackTmodReader]::Read($candidate.FullName)
            if ($actual.Name -eq $Expected.name -and $actual.Sha256 -eq $Expected.sha256) { $matching += $actual }
        } catch { $errors += "$($candidate.FullName): $($_.Exception.Message)" }
    }
    if ($errors.Count) { throw ('Corrupt/unknown Workshop payload: ' + ($errors -join '; ')) }
    if ($matching.Count -ne 1) { throw "Expected exactly one audited .tmod for $($Expected.name); found $($matching.Count). Wrong branch, duplicate, or Workshop update. No changes installed." }
    return Test-PackMod $matching[0].Path $Expected $TargetTml
}
function Test-PackDependencies($Mods, $ManifestEntries) {
    $index = @{}; foreach ($mod in $Mods) { if ($index.ContainsKey($mod.Name)) { throw "Duplicate internal name: $($mod.Name)" }; $index[$mod.Name] = $mod }
    foreach ($mod in $Mods) {
        foreach ($spec in @($mod.Required) + @($mod.Weak)) {
            $parts = $spec -split '@'; $name = $parts[0]
            if (-not $index.ContainsKey($name)) {
                if ($spec -in $mod.Required) { throw "Missing dependency: $($mod.Name) -> $name" }; continue
            }
            if ($parts.Count -eq 2) {
                $have = [version]$index[$name].Version; $need = [version]$parts[1]
                if ($have -lt $need -or $have.Major -ne $need.Major) { throw "Dependency version mismatch: $($mod.Name) needs $spec, found $have" }
            }
        }
    }
    foreach ($entry in $ManifestEntries) { foreach ($name in $entry.additionalRequired) { if (-not $index.ContainsKey($name)) { throw "Missing practical dependency: $($entry.name) -> $name" } } }
    # Cycle detection on hard dependency edges.
    $visited=@{}; $active=@{}
    function Visit-PackNode($Name) {
        if ($active.ContainsKey($Name)) { throw "Dependency cycle at $Name" }
        if ($visited.ContainsKey($Name)) { return }
        $active[$Name]=$true
        foreach($ref in $index[$Name].Required) { Visit-PackNode (($ref -split '@')[0]) }
        $active.Remove($Name); $visited[$Name]=$true
    }
    foreach($name in $index.Keys) { Visit-PackNode $name }
}
function Get-PackSteamRoots {
    $roots=@()
    $reg=Get-ItemProperty -LiteralPath 'HKCU:\Software\Valve\Steam' -ErrorAction SilentlyContinue
    if ($reg -and $reg.PSObject.Properties['SteamPath']) {
        $roots += [IO.Path]::GetFullPath($reg.SteamPath)
        $vdf=Join-Path $reg.SteamPath 'steamapps\libraryfolders.vdf'
        if (Test-Path -LiteralPath $vdf) {
            foreach($match in [regex]::Matches((Get-Content -LiteralPath $vdf -Raw),'"path"\s+"([^"]+)"')) { $roots += $match.Groups[1].Value.Replace('\\','\') }
        }
    }
    return @($roots | Select-Object -Unique)
}
function Get-PackTml($TmlPath) {
    $candidates=@()
    if ($TmlPath) { $candidates += $TmlPath } else { foreach($root in Get-PackSteamRoots) { $candidates += Join-Path $root 'steamapps\common\tModLoader' } }
    foreach($folder in $candidates) {
        $dll=Join-Path $folder 'tModLoader.dll'
        if (Test-Path -LiteralPath $dll -PathType Leaf) {
            $v=[Diagnostics.FileVersionInfo]::GetVersionInfo($dll).ProductVersion
            if ($v -match '^1\.4\.4\.9\+(\d+\.\d+\.\d+\.\d+)\|[^|]+\|stable\|') { return [pscustomobject]@{Path=[IO.Path]::GetFullPath($folder);Version=[version]$Matches[1];ProductVersion=$v} }
            throw "tModLoader is not a recognized stable 1.4.4.9 installation: $v"
        }
    }
    throw 'tModLoader was not found. Install Terraria and tModLoader through Steam, select the stable 1.4.4 branch, launch once, close it, and retry. Download-only mode does not require the game.'
}
function Read-PackTmlPath([version]$TargetVersion) {
    Write-Host ''
    Write-Host 'Informe a pasta onde o tModLoader esta INSTALADO (a que contem tModLoader.dll).'
    Write-Host 'Exemplo: E:\SteamLibrary\steamapps\common\tModLoader'
    Write-Host 'Aceita caminho com ou sem aspas. ENTER tenta detectar pela Steam; 0 cancela.'
    for ($attempt=1; $attempt -le 5; $attempt++) {
        $entered=Read-Host 'Pasta do tModLoader'
        $entered=([string]$entered).Trim()
        if ($entered -eq '0') { throw [OperationCanceledException]::new('Operacao cancelada antes de alterar mods ou saves.') }
        try {
            if ($entered.Length -ge 2 -and (($entered.StartsWith('"') -and $entered.EndsWith('"')) -or ($entered.StartsWith("'") -and $entered.EndsWith("'")))) {
                $entered=$entered.Substring(1,$entered.Length-2)
            }
            if ($entered) {
                if ($entered -notmatch '^(?:[A-Za-z]:[\\/]|\\\\[^\\/]+[\\/][^\\/]+)') { throw 'Cole o caminho completo da pasta, incluindo a unidade (por exemplo E:\...).'
                }
                if (-not (Test-Path -LiteralPath $entered -PathType Container)) { throw 'Esta pasta nao existe. Confira o caminho no Explorador de Arquivos.' }
                if (-not (Test-Path -LiteralPath (Join-Path $entered 'tModLoader.dll') -PathType Leaf)) { throw 'tModLoader.dll nao encontrado. Selecione a pasta do JOGO, nao a pasta do pacote ou dos saves.' }
            }
            $found=Get-PackTml $entered
            if ($found.Version -ne $TargetVersion) { throw "Versao encontrada: $($found.Version). Este pacote exige tModLoader $TargetVersion; nao houve alteracao no jogo." }
            return $found.Path
        } catch {
            Write-Host ('Instalacao nao aceita: '+$_.Exception.Message) -ForegroundColor Yellow
        }
    }
    throw 'Nao foi possivel validar a instalacao apos 5 tentativas. Execute novamente e informe a pasta do tModLoader.'
}
function Assert-PackGameClosed {
    $running = @(Get-CimInstance Win32_Process | Where-Object { $_.Name -match '^tModLoader' -or ($_.Name -eq 'dotnet.exe' -and $_.CommandLine -match 'tModLoader\.dll') })
    if ($running.Count) { throw 'Close every tModLoader client/server before changing mods or restoring a backup.' }
}
function Get-PackLocalConflicts($SavePath, $Selected) {
    $modsDir = Get-PackPath $SavePath 'Mods'
    # tML 2026.8 scans only the top level for local mods. Nested archives are not active local copies.
    $paths=@(Get-ChildItem -LiteralPath $modsDir -Filter '*.tmod' -File -ErrorAction SilentlyContinue)
    foreach($path in $paths) {
        Get-PackPath $SavePath ('Mods\'+$path.Name) | Out-Null
        $info=[PackTmodReader]::Read($path.FullName)
        if ($info.Name -in $Selected.name) {
            $expected=Get-PackPath $SavePath ('Mods\'+$info.Name+'.tmod')
            if ($path.FullName -ne $expected) { $info }
        }
    }
}
function Test-PackLocalDuplicates($SavePath, $Selected, [switch]$AllowLocalConflicts) {
    $conflicts=@(Get-PackLocalConflicts $SavePath $Selected)
    if ($conflicts.Count -and -not $AllowLocalConflicts) {
        throw ("Local mod copies conflict with the pack filenames: " + (($conflicts | ForEach-Object {$_.Path}) -join '; ') + '. Use menu option 7 (Install + backup local conflicts), or move those files out of Mods manually. The destination is detected for this Windows user.')
    }
    foreach($root in Get-PackSteamRoots) {
        $content=Join-Path $root 'steamapps\workshop\content\1281930'
        # Scan all item folders: forks/reuploads can share an internal name.
        foreach($path in @(Get-ChildItem -LiteralPath $content -Filter '*.tmod' -Recurse -File -ErrorAction SilentlyContinue)) {
            $info=[PackTmodReader]::Read($path.FullName)
            if ($info.Name -in $Selected.name) { throw "Workshop/local duplicate: $($info.Name) at $($path.FullName). Unsubscribe that copy through Steam and verify its removal before using local pinned files." }
        }
    }
    return $conflicts
}
function Get-PackSteamCmd($CachePath) {
    $folder=Join-Path $CachePath 'steamcmd'; $exe=Join-Path $folder 'steamcmd.exe'
    if (-not (Test-Path -LiteralPath $exe)) {
        [IO.Directory]::CreateDirectory($folder) | Out-Null
        $zip=Join-Path $CachePath 'steamcmd.zip'
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        $web=[Net.WebClient]::new()
        try {$web.DownloadFile('https://steamcdn-a.akamaihd.net/client/installer/steamcmd.zip',$zip)}finally{$web.Dispose()}
        Add-Type -AssemblyName System.IO.Compression.FileSystem
        $archive=[IO.Compression.ZipFile]::OpenRead($zip)
        try {
            foreach($entry in $archive.Entries) {
                $destination=Get-PackPath $folder $entry.FullName
                if(-not $entry.Name){[IO.Directory]::CreateDirectory($destination)|Out-Null;continue}
                [IO.Directory]::CreateDirectory((Split-Path -Parent $destination))|Out-Null
                [IO.Compression.ZipFileExtensions]::ExtractToFile($entry,$destination,$true)
            }
        }finally{$archive.Dispose()}
    }
    if (-not (Test-Path -LiteralPath $exe)) { throw 'SteamCMD bootstrap did not produce steamcmd.exe' }
    return $exe
}
function Invoke-PackDownloads($Selected, $CachePath, $ReportPath) {
    $exe=Get-PackSteamCmd $CachePath
    $runScript=Join-Path $ReportPath 'steamcmd-script.txt'
    $lines=@('@ShutdownOnFailedCommand 0','@NoPromptForPassword 1','login anonymous')
    foreach($m in $Selected) { $lines += "workshop_download_item 1281930 $($m.workshopId) validate" }; $lines += 'quit'
    [IO.File]::WriteAllLines($runScript, $lines, [Text.UTF8Encoding]::new($false))
    Write-Host 'Downloading from Steam Workshop. The log is updated in the report folder.'
    $oldPreference=$ErrorActionPreference; $ErrorActionPreference='Continue'
    try { & $exe '+runscript' $runScript > (Join-Path $ReportPath 'steamcmd.log') 2>&1; $code=$LASTEXITCODE }
    finally { $ErrorActionPreference=$oldPreference }
    $log=Get-Content -LiteralPath (Join-Path $ReportPath 'steamcmd.log') -Raw
    # SteamCMD may report exit 1 after a successful first-run self-update.
    # Require a per-item success receipt AND validate the actual bytes afterwards.
    $receipts=@{}
    foreach($m in $Selected) { $receipts[$m.workshopId]=[bool]($log -match ('Success\. Downloaded item '+[regex]::Escape($m.workshopId)+'\b')) }
    return [pscustomobject]@{ExitCode=$code;Receipts=$receipts}
}
function New-PackTransaction($SavePath, $BackupRoot, $Changes) {
    $id=(Get-Date -Format 'yyyyMMdd-HHmmss')+'-'+[guid]::NewGuid().ToString('N').Substring(0,8)
    $backup=Join-Path $BackupRoot $id
    [IO.Directory]::CreateDirectory($backup) | Out-Null
    $entries=@()
    foreach($change in $Changes) {
        $action=if($change.PSObject.Properties['action']){$change.action}else{'write'}
        if($action -notin @('write','archive')) { throw 'Unsupported transaction action' }
        $target=Get-PackPath $SavePath $change.relative
        $had=Test-Path -LiteralPath $target
        $oldHash=$null
        if($action -eq 'archive') {
            if($change.relative -notmatch '^Mods\\[^\\/]+\.tmod$' -or -not $had) { throw 'Archiving is restricted to existing top-level local .tmod files.' }
            if((Get-PackHash $target) -ne $change.expectedHash) { throw "Local file changed since conflict scan: $target" }
        }
        if ($had) {
            $oldHash=Get-PackHash $target
            $dest=Get-PackPath $backup ('files\'+$change.relative)
            [IO.Directory]::CreateDirectory((Split-Path -Parent $dest)) | Out-Null
            [IO.File]::Copy($target,$dest,$false)
            if ((Get-PackHash $dest) -ne $oldHash) { throw "Backup failed verification: $target" }
        }
        $newHash=if($action -eq 'write'){Get-PackHash $change.source}else{$null}
        $entries += [pscustomobject]@{relative=$change.relative;action=$action;existed=$had;oldHash=$oldHash;newHash=$newHash}
    }
    $journal=[pscustomobject]@{schema=1;savePath=[IO.Path]::GetFullPath($SavePath);state='prepared';entries=$entries}
    Write-PackJson (Join-Path $backup 'transaction.json') $journal
    try {
        foreach($change in $Changes) {
            $target=Get-PackPath $SavePath $change.relative
            if($change.PSObject.Properties['action'] -and $change.action -eq 'archive') {
                # An exact, validated file already copied and hash-verified in this transaction's backup.
                if((Get-PackHash $target) -ne $change.expectedHash) { throw "Local file changed before archival: $target" }
                [IO.File]::Delete($target)
                continue
            }
            [IO.Directory]::CreateDirectory((Split-Path -Parent $target)) | Out-Null
            $temporary=$target+'.pack-new-'+$id
            try {
                [IO.File]::Copy($change.source,$temporary,$false)
                if ((Get-PackHash $temporary) -ne (Get-PackHash $change.source)) { throw "Copy checksum mismatch: $target" }
                if (Test-Path -LiteralPath $target) { [PackTmodReader]::AtomicReplace($temporary,$target) }
                else { [IO.File]::Move($temporary,$target) }
            } finally { if (Test-Path -LiteralPath $temporary) { [IO.File]::Delete($temporary) } }
        }
        $journal.state='committed'; Write-PackJson (Join-Path $backup 'transaction.json') $journal
    } catch {
        $failure=$_
        try { Restore-PackTransaction $backup -Rollback; $journal.state='rolled-back'; Write-PackJson (Join-Path $backup 'transaction.json') $journal }
        catch { throw "INSTALL AND ROLLBACK FAILED. Backup: $backup. Original error: $failure. Recovery error: $_" }
        throw "Install failed; previous files restored. Cause: $failure"
    }
    return $backup
}
function Restore-PackTransaction($BackupPath, [switch]$Rollback) {
    $file=Join-Path $BackupPath 'transaction.json'; $journal=Read-PackJson $file
    if ($journal.schema -ne 1 -or $journal.state -notin @('prepared','committed')) { throw 'Backup is not an active supported transaction' }
    foreach($entry in $journal.entries) {
        $target=Get-PackPath $journal.savePath $entry.relative
        if (-not $Rollback) {
            if($entry.PSObject.Properties['action'] -and $entry.action -eq 'archive') {
                if(Test-Path -LiteralPath $target) { throw "Archived path was recreated after installation: $target. Back it up and restore manually." }
            } elseif (-not (Test-Path -LiteralPath $target) -or (Get-PackHash $target) -ne $entry.newHash) { throw "File changed since installation: $target. Back it up and restore manually; automatic restore will not overwrite later changes." }
        }
        if ($entry.existed) {
            $source=Get-PackPath $BackupPath ('files\'+$entry.relative)
            if (-not (Test-Path -LiteralPath $source) -or (Get-PackHash $source) -ne $entry.oldHash) { throw "Backup damaged: $source" }
        }
    }
    foreach($entry in $journal.entries) {
        $target=Get-PackPath $journal.savePath $entry.relative
        if ($entry.existed) {
            $source=Get-PackPath $BackupPath ('files\'+$entry.relative)
            [IO.File]::Copy($source,$target,$true)
        } elseif (Test-Path -LiteralPath $target) {
            # Only a specifically journaled new file, never a recursive delete.
            [IO.File]::Delete($target)
        }
    }
    $journal.state=if($Rollback){'rolled-back'}else{'restored'}
    Write-PackJson $file $journal
}
Export-ModuleMember -Function *-Pack*
