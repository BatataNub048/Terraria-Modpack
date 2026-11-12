#requires -Version 5.1
$ErrorActionPreference = 'Stop'
$pack = Split-Path $PSScriptRoot -Parent
Import-Module (Join-Path $pack 'lib\WorldSafety.psm1') -Force
Import-Module (Join-Path $pack 'lib\Pack.psm1') -Force
$fixtures = Join-Path ([IO.Path]::GetTempPath()) ('TerrariaTitanSafety-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $fixtures | Out-Null
$fixtureId = [guid]'00112233-4455-4677-8899-aabbccddeeff'

function New-WorldFixture([string]$Name, [int]$Width, [int]$Height) {
    $path = Join-Path $fixtures $Name
    $stream = [IO.File]::Create($path)
    $writer = [IO.BinaryWriter]::new($stream)
    try {
        $writer.Write([int]279)
        $writer.Write([Text.Encoding]::ASCII.GetBytes("relogic"))
        $writer.Write([byte]2)
        $writer.Write([uint32]1)
        $writer.Write([uint64]0)
        $writer.Write([int16]1)
        $writer.Write([int]128)
        $stream.Position = 128
        $writer.Write('Fixture')
        $writer.Write('seed')
        $writer.Write([uint64]0)
        $writer.Write($fixtureId.ToByteArray())
        foreach ($value in @(1,0,($Width*16),0,($Height*16),$Height,$Width,1)) { $writer.Write([int]$value) }
        $stream.SetLength(512)
    }
    finally { $writer.Dispose() }
    return $path
}

$normal = New-WorldFixture 'normal.wld' 8400 2400
$titan = New-WorldFixture 'titan.wld' 16800 4800
$legacy = New-WorldFixture 'legacy.wld' 16000 8000
Assert-PackWorldFile $normal $false
Assert-PackWorldFile $titan $true
if ((Get-PackWorldHeader $titan).UniqueId -ne $fixtureId) { throw 'World GUID was not decoded correctly.' }
foreach ($world in @($titan,$legacy)) {
    $blocked = $false
    try { Assert-PackWorldFile $world $false } catch { $blocked = $_.Exception.Message -match 'bloqueado' }
    if (-not $blocked) { throw "Expanded world was not blocked: $world" }
}
$invalid = Join-Path $fixtures 'invalid.wld'
[IO.File]::WriteAllBytes($invalid, [byte[]]@(0,0,0))
$blocked = $false
try { Assert-PackWorldFile $invalid $false } catch { $blocked = $true }
if (-not $blocked) { throw 'Truncated world was accepted.' }

foreach ($base in @('Ampliado','TodosRecuperados')) {
    $original = Read-PackJson (Join-Path $pack "profiles\$base.lock.json")
    $expanded = Read-PackJson (Join-Path $pack "profiles\$base-Titanico.lock.json")
    $oldMods = ConvertTo-Json -InputObject @($original.mods) -Depth 30 -Compress
    $newBase = ConvertTo-Json -InputObject @($expanded.mods | Where-Object name -ne TitanWorlds) -Depth 30 -Compress
    if ($oldMods -cne $newBase) { throw "Base mods changed in $base-Titanico" }
    if ($expanded.mods.Count -ne $original.mods.Count + 1) { throw 'Unexpected mod count.' }
    $selection = @(Get-PackSelection $expanded 5 @())
    if ('miningcracks_take_on_luiafk' -notin $selection.name) { throw 'LuiAFK is missing.' }
    $basePresets = ConvertTo-Json -InputObject @($original.presets) -Depth 30 -Compress
    $expandedBasePresets = ConvertTo-Json -InputObject @($expanded.presets | Where-Object file -ne TitanWorlds_TitanWorldServerConfig.json) -Depth 30 -Compress
    if ($basePresets -cne $expandedBasePresets) { throw "Original presets changed in $base-Titanico" }
}
Write-Output 'Passed: world GUID, normal world, Titan world, legacy Titan rejection, truncated file, exact profile inheritance, LuiAFK and presets.'
Write-Output "Temporary fixtures: $fixtures"
