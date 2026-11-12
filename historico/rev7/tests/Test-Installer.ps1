#requires -Version 5.1
[CmdletBinding()]param([string]$CachePath)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$pack=Split-Path -Parent $PSScriptRoot
Import-Module (Join-Path $pack 'lib\Pack.psm1') -Force
$manifest=Read-PackJson (Join-Path $pack 'manifest.lock.json')
$testRoot=Join-Path $env:TEMP ('TerrariaPack-test-'+[guid]::NewGuid().ToString('N'))
[IO.Directory]::CreateDirectory($testRoot) | Out-Null
$results=[Collections.Generic.List[object]]::new()
function Check($Name,[scriptblock]$Test) {
    try { & $Test; $results.Add([pscustomobject]@{name=$Name;passed=$true;error='' }); Write-Host "PASS $Name" }
    catch {$results.Add([pscustomobject]@{name=$Name;passed=$false;error=$_.Exception.Message}); Write-Host "FAIL $Name : $_"}
}
function Assert($Condition,$Message) {if(-not $Condition){throw $Message}}
function Must-Fail([scriptblock]$Action) { $failed=$false;try{& $Action | Out-Null}catch{$failed=$true};Assert $failed 'Expected rejection, but operation succeeded' }
Check 'All PowerShell files parse on Windows PowerShell 5.1' {
    foreach($file in Get-ChildItem -LiteralPath $pack -Recurse -File | Where-Object Extension -in @('.ps1','.psm1')) {
        $tokens=$null;$errors=$null
        [Management.Automation.Language.Parser]::ParseFile($file.FullName,[ref]$tokens,[ref]$errors) | Out-Null
        Assert ($errors.Count -eq 0) ($errors -join '; ')
    }
}
Check 'All six stages form complete dependency closures' {
    foreach($stage in 1..6) { $mods=@(Get-PackSelection $manifest $stage @('extras','wings','performance'));Assert ($mods.Count -gt 0) 'Empty stage' }
}
Check 'Manifest rejects duplicate internal names' {
    $copy=($manifest | ConvertTo-Json -Depth 40 | ConvertFrom-Json);$copy.mods += $copy.mods[0]
    Must-Fail {Get-PackSelection $copy 5 @()}
}
Check 'Manifest rejects missing library dependency' {
    $copy=($manifest | ConvertTo-Json -Depth 40 | ConvertFrom-Json);$copy.mods=@($copy.mods|Where-Object name -ne 'SerousCommonLib')
    Must-Fail {Get-PackSelection $copy 5 @()}
}
Check 'Path traversal cannot escape save or backup root' {Must-Fail {Get-PackPath $testRoot '..\outside.txt'}}
Check 'enabled.json round-trip is a flat string array on PowerShell 5.1' {
    $path=Join-Path $testRoot 'array.json';Write-PackJson $path @('A','B')
    $items=@(Read-PackJson $path)
    Assert ($items.Count -eq 2 -and $items[0] -is [string] -and $items[1] -eq 'B') 'JSON arrays were nested'
}
Check 'Transaction preserves unrelated files and restores replaced/new files' {
    $save=Join-Path $testRoot 'save';$backup=Join-Path $testRoot 'backups'
    [IO.Directory]::CreateDirectory((Join-Path $save 'Mods'))|Out-Null
    [IO.File]::WriteAllText((Join-Path $save 'Mods\enabled.json'),'["Unrelated"]')
    [IO.File]::WriteAllText((Join-Path $save 'unrelated.txt'),'untouched')
    $a=Join-Path $testRoot 'new-enabled.json';[IO.File]::WriteAllText($a,'["Selected"]')
    $b=Join-Path $testRoot 'payload';[IO.File]::WriteAllText($b,'new file')
    $journal=New-PackTransaction $save $backup @([pscustomobject]@{relative='Mods\enabled.json';source=$a},[pscustomobject]@{relative='Mods\New.tmod';source=$b})
    Assert ((Get-Content -LiteralPath (Join-Path $save 'Mods\enabled.json') -Raw) -eq '["Selected"]') 'Enabled not updated'
    Restore-PackTransaction $journal
    Assert ((Get-Content -LiteralPath (Join-Path $save 'Mods\enabled.json') -Raw) -eq '["Unrelated"]') 'Old enabled not restored'
    Assert (-not(Test-Path -LiteralPath (Join-Path $save 'Mods\New.tmod'))) 'New mod not removed during restore'
    Assert ((Get-Content -LiteralPath (Join-Path $save 'unrelated.txt') -Raw) -eq 'untouched') 'Unrelated changed'
}
Check 'Restore refuses files edited after installation' {
    $save=Join-Path $testRoot 'edited-save';$source=Join-Path $testRoot 'source';[IO.File]::WriteAllText($source,'initial')
    $journal=New-PackTransaction $save (Join-Path $testRoot 'backups') @([pscustomobject]@{relative='new.txt';source=$source})
    [IO.File]::WriteAllText((Join-Path $save 'new.txt'),'user edit')
    Must-Fail {Restore-PackTransaction $journal}
    Assert ((Get-Content -LiteralPath (Join-Path $save 'new.txt') -Raw) -eq 'user edit') 'User edit overwritten'
}
Check 'Copy failure rolls back previous writes' {
    $save=Join-Path $testRoot 'rollback-save';[IO.Directory]::CreateDirectory($save)|Out-Null
    [IO.File]::WriteAllText((Join-Path $save 'first.txt'),'old')
    [IO.File]::WriteAllText((Join-Path $save 'blocked'),'file prevents a directory')
    $source=Join-Path $testRoot 'rollback-source';[IO.File]::WriteAllText($source,'new')
    Must-Fail {New-PackTransaction $save (Join-Path $testRoot 'backups') @([pscustomobject]@{relative='first.txt';source=$source},[pscustomobject]@{relative='blocked\second.txt';source=$source})}
    Assert ((Get-Content -LiteralPath (Join-Path $save 'first.txt') -Raw) -eq 'old') 'Partial change was left behind'
}
Check 'Dependency versions and conditional weak dependencies are enforced' {
    $a=[pscustomobject]@{Name='A';Version='1.0';Required=@('B@2.0');Weak=@('Absent@3.0')}
    $b=[pscustomobject]@{Name='B';Version='1.0';Required=@();Weak=@()}
    Must-Fail {Test-PackDependencies @($a,$b) @()}
    $b.Version='2.1';Test-PackDependencies @($a,$b) @()
    $a.Weak=@('B@3.0');Must-Fail {Test-PackDependencies @($a,$b) @()}
}
Check 'Dependency cycles are rejected' {
    $a=[pscustomobject]@{Name='A';Version='1.0';Required=@('B');Weak=@()}
    $b=[pscustomobject]@{Name='B';Version='1.0';Required=@('A');Weak=@()}
    Must-Fail {Test-PackDependencies @($a,$b) @()}
}
Check 'Conflicting local mod is backed up and can be restored; other saves stay intact' {
    $save=Join-Path $testRoot 'archive-save';$mods=Join-Path $save 'Mods'
    [IO.Directory]::CreateDirectory($mods)|Out-Null
    $old=Join-Path $mods '2025.12Example.tmod';[IO.File]::WriteAllText($old,'original bytes')
    [IO.File]::WriteAllText((Join-Path $save 'world.wld'),'world remains')
    [IO.File]::WriteAllText((Join-Path $mods 'Unrelated.tmod'),'unrelated remains')
    $hash=Get-PackHash $old
    $backup=New-PackTransaction $save (Join-Path $testRoot 'backups') @([pscustomobject]@{relative='Mods\2025.12Example.tmod';action='archive';expectedHash=$hash})
    Assert (-not(Test-Path -LiteralPath $old)) 'Conflicting file still active'
    Assert ((Get-PackHash (Join-Path $backup 'files\Mods\2025.12Example.tmod')) -eq $hash) 'Backup differs'
    Restore-PackTransaction $backup
    Assert ((Get-PackHash $old) -eq $hash) 'Original not restored'
    Assert ((Get-Content -LiteralPath (Join-Path $save 'world.wld') -Raw) -eq 'world remains') 'World changed'
    Assert ((Get-Content -LiteralPath (Join-Path $mods 'Unrelated.tmod') -Raw) -eq 'unrelated remains') 'Unrelated mod changed'
}
Check 'Restore refuses to overwrite a recreated archived path' {
    $save=Join-Path $testRoot 'archive-recreated';[IO.Directory]::CreateDirectory((Join-Path $save 'Mods'))|Out-Null
    $path=Join-Path $save 'Mods\Old.tmod';[IO.File]::WriteAllText($path,'original')
    $backup=New-PackTransaction $save (Join-Path $testRoot 'backups') @([pscustomobject]@{relative='Mods\Old.tmod';action='archive';expectedHash=(Get-PackHash $path)})
    [IO.File]::WriteAllText($path,'new user data');Must-Fail {Restore-PackTransaction $backup}
    Assert ((Get-Content -LiteralPath $path -Raw) -eq 'new user data') 'Later file overwritten'
}
Check 'Changed conflict cannot be archived after scan' {
    $save=Join-Path $testRoot 'archive-race';[IO.Directory]::CreateDirectory((Join-Path $save 'Mods'))|Out-Null
    $path=Join-Path $save 'Mods\Old.tmod';[IO.File]::WriteAllText($path,'original');$hash=Get-PackHash $path
    [IO.File]::WriteAllText($path,'changed later')
    Must-Fail {New-PackTransaction $save (Join-Path $testRoot 'backups') @([pscustomobject]@{relative='Mods\Old.tmod';action='archive';expectedHash=$hash})}
    Assert ((Get-Content -LiteralPath $path -Raw) -eq 'changed later') 'Changed file lost'
}
Check 'Later copy failure rolls back archived mod' {
    $save=Join-Path $testRoot 'archive-rollback';[IO.Directory]::CreateDirectory((Join-Path $save 'Mods'))|Out-Null
    $path=Join-Path $save 'Mods\Old.tmod';[IO.File]::WriteAllText($path,'original');$hash=Get-PackHash $path
    [IO.File]::WriteAllText((Join-Path $save 'blocked'),'blocked directory')
    $source=Join-Path $testRoot 'archive-new-source';[IO.File]::WriteAllText($source,'payload')
    Must-Fail {New-PackTransaction $save (Join-Path $testRoot 'backups') @([pscustomobject]@{relative='Mods\Old.tmod';action='archive';expectedHash=$hash},[pscustomobject]@{relative='blocked\file';source=$source})}
    Assert ((Get-PackHash $path) -eq $hash) 'Archived file not restored after failure'
}
Check 'Archival is restricted to top-level Mods files' {
    $save=Join-Path $testRoot 'archive-scope';[IO.Directory]::CreateDirectory($save)|Out-Null
    $path=Join-Path $save 'world.tmod';[IO.File]::WriteAllText($path,'preserve')
    Must-Fail {New-PackTransaction $save (Join-Path $testRoot 'backups') @([pscustomobject]@{relative='world.tmod';action='archive';expectedHash=(Get-PackHash $path)})}
    Assert (Test-Path -LiteralPath $path) 'Out-of-scope file removed'
}
Check 'Conflict scan works on Unicode paths and ignores inactive nested archives' {
    $save=Join-Path $testRoot ('Other PC - Jo'+[char]0x00e3+'o & !');$mods=Join-Path $save 'Mods'
    [IO.Directory]::CreateDirectory((Join-Path $mods '2025.12'))|Out-Null
    $guard=Join-Path $pack 'bundled\TerrariaPackGuard.tmod'
    $entry=$manifest.mods|Where-Object name -eq 'TerrariaPackGuard'
    [IO.File]::Copy($guard,(Join-Path $mods '2025.12\TerrariaPackGuard.tmod'))
    Assert (@(Get-PackLocalConflicts $save @($entry)).Count -eq 0) 'Nested archive incorrectly blocked'
    [IO.File]::Copy($guard,(Join-Path $mods '2025.12TerrariaPackGuard.tmod'))
    $conflicts=@(Get-PackLocalConflicts $save @($entry))
    Assert ($conflicts.Count -eq 1 -and $conflicts[0].Name -eq 'TerrariaPackGuard') 'Prefixed local file not detected'
    [IO.File]::Copy($guard,(Join-Path $mods 'TerrariaPackGuard.tmod'))
    Assert (@(Get-PackLocalConflicts $save @($entry)).Count -eq 1) 'Canonical path incorrectly marked as conflict'
}
Check 'Restore remains compatible with pre-revision-4 backup journals' {
    $save=Join-Path $testRoot 'legacy-journal';[IO.Directory]::CreateDirectory($save)|Out-Null
    [IO.File]::WriteAllText((Join-Path $save 'original.txt'),'old')
    $source=Join-Path $testRoot 'legacy-source';[IO.File]::WriteAllText($source,'new')
    $backup=New-PackTransaction $save (Join-Path $testRoot 'backups') @([pscustomobject]@{relative='original.txt';source=$source})
    $path=Join-Path $backup 'transaction.json';$journal=Read-PackJson $path
    foreach($entry in $journal.entries){$entry.PSObject.Properties.Remove('action')}
    Write-PackJson $path $journal
    Restore-PackTransaction $backup
    Assert ((Get-Content -LiteralPath (Join-Path $save 'original.txt') -Raw) -eq 'old') 'Legacy journal restore failed'
}
if ($CachePath) {
    Check 'All real binaries in this manifest; identity, version, hash and dependencies' {
        $infos=@();foreach($m in $manifest.mods) {
            if($m.source -eq 'bundled'){$infos+=Test-PackMod (Join-Path $pack ('bundled\'+$m.name+'.tmod')) $m ([version]$manifest.targetTml)}
            else{$infos+=Find-PackMod (Join-Path $CachePath ('steamcmd\steamapps\workshop\content\1281930\'+$m.workshopId)) $m ([version]$manifest.targetTml)}
        }
        Test-PackDependencies $infos $manifest.mods
    }
    Check 'Truncated and bit-corrupted real TMODs are rejected' {
        $m=$manifest.mods|Where-Object name -eq 'NoFishingQuests'
        $info=Find-PackMod (Join-Path $CachePath ('steamcmd\steamapps\workshop\content\1281930\'+$m.workshopId)) $m ([version]$manifest.targetTml)
        $bytes=[IO.File]::ReadAllBytes($info.Path);$bad=Join-Path $testRoot 'bad.tmod'
        [IO.File]::WriteAllBytes($bad,$bytes[0..100]);Must-Fail {[PackTmodReader]::Read($bad)}
        $bytes[$bytes.Length-1]=$bytes[$bytes.Length-1] -bxor 1;[IO.File]::WriteAllBytes($bad,$bytes);Must-Fail {[PackTmodReader]::Read($bad)}
    }
    Check 'Workshop duplicate matching payload is rejected' {
        $m=$manifest.mods|Where-Object name -eq 'NoFishingQuests'
        $info=Find-PackMod (Join-Path $CachePath ('steamcmd\steamapps\workshop\content\1281930\'+$m.workshopId)) $m ([version]$manifest.targetTml)
        $folder=Join-Path $testRoot 'duplicate';[IO.Directory]::CreateDirectory($folder)|Out-Null
        [IO.File]::Copy($info.Path,(Join-Path $folder 'a.tmod'));[IO.File]::Copy($info.Path,(Join-Path $folder 'b.tmod'))
        Must-Fail {Find-PackMod $folder $m ([version]$manifest.targetTml)}
    }
}
$output=Join-Path $pack 'reports\installer-tests.json'
Write-PackJson $output @($results.ToArray())
Write-Host "Evidence: $output / Fixtures: $testRoot"
if(@($results|Where-Object {-not $_.passed}).Count){exit 1}else{exit 0}
