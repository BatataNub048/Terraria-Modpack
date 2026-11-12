#requires -Version 5.1
[CmdletBinding()]
param(
    [ValidateSet('Ampliado','TodosRecuperados','Ampliado-Titanico','TodosRecuperados-Titanico','TodosRecuperados-Titanico-Desempenho')][string]$Perfil = 'Ampliado',
    [ValidateSet('Preparar','Verificar','Cliente','Servidor')][string]$Modo = 'Preparar',
    [string]$PastaTml = '',
    [ValidateRange(1024,65535)][int]$Porta = 17779,
    [string]$Endereco = '127.0.0.1'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
Import-Module (Join-Path $PSScriptRoot 'lib\Pack.psm1') -Force
Import-Module (Join-Path $PSScriptRoot 'lib\WorldSafety.psm1') -Force
$manifest = Read-PackJson (Join-Path $PSScriptRoot ('profiles\' + $Perfil + '.lock.json'))
$target = [version]$manifest.targetTml
$selected = @(Get-PackSelection $manifest 5 @())
$profileRoot = Get-PackPath $PSScriptRoot ('saves\' + $Perfil)

if ($Modo -in @('Cliente','Servidor')) {
    $tml = Get-PackTml $PastaTml
    if ($tml.Version -ne $target) {
        throw "Este perfil usa tModLoader $target. Versao encontrada: $($tml.Version)."
    }
    $runtime = Join-Path $tml.Path 'dotnet\dotnet.exe'
    if (-not (Test-Path -LiteralPath $runtime -PathType Leaf)) {
        throw 'Abra o tModLoader pela Steam uma vez para preparar seu runtime local.'
    }
}

function Test-ProfileFiles([string]$Root) {
    $enabled = @(Read-PackJson (Get-PackPath $Root 'Mods\enabled.json'))
    if (@(Compare-Object ($enabled | Sort-Object) ($selected.name | Sort-Object)).Count) {
        throw 'A lista de mods ativos diverge do perfil. Preserve a pasta do perfil antes de experimentar alteracoes.'
    }

    $modFiles = @(Get-ChildItem -LiteralPath (Get-PackPath $Root 'Mods') -File -Filter '*.tmod')
    if (@(Compare-Object ($modFiles.BaseName | Sort-Object) ($selected.name | Sort-Object)).Count) {
        throw 'A pasta Mods contem arquivos ausentes ou extras.'
    }

    $infos = foreach ($mod in $selected) {
        Test-PackMod (Get-PackPath $Root ('Mods\' + $mod.name + '.tmod')) $mod $target
    }
    Test-PackDependencies @($infos) $selected
    if ('TitanWorlds' -in $selected.name) {
        $titanConfig = Read-PackJson (Get-PackPath $Root 'ModConfigs\TitanWorlds_TitanWorldServerConfig.json')
        if ($titanConfig.ForceTitanWorldOnDedicatedServer -ne $true) {
            throw 'A configuracao TitanWorlds exige ForceTitanWorldOnDedicatedServer=true neste perfil.'
        }
    }
}

if ($Perfil -eq 'TodosRecuperados-Titanico-Desempenho' -and
    -not (Test-Path -LiteralPath $profileRoot) -and $Modo -ne 'Verificar') {
    & (Join-Path $PSScriptRoot 'Preparar-Desempenho.ps1')
}

if (-not (Test-Path -LiteralPath $profileRoot)) {
    if ($Modo -eq 'Verificar') { throw 'Prepare este perfil primeiro.' }

    # Publish the save directory only after checking every copied mod.
    $stagedRoot = Get-PackPath $PSScriptRoot ('saves\' + $Perfil + '.preparando-' + [guid]::NewGuid().ToString('N'))
    New-Item -ItemType Directory -Path (Join-Path $stagedRoot 'Mods'),(Join-Path $stagedRoot 'ModConfigs'),(Join-Path $stagedRoot 'Worlds') -Force | Out-Null
    foreach ($mod in $selected) {
        $fileName = $mod.name + '.tmod'
        $payloadRelative = $fileName
        if ($mod.PSObject.Properties.Name -contains 'payloadFile') { $payloadRelative = [string]$mod.payloadFile }
        $payload = Get-PackPath (Join-Path $PSScriptRoot 'payload') $payloadRelative
        Copy-Item -LiteralPath $payload -Destination (Join-Path $stagedRoot ('Mods\' + $fileName))
    }
    Write-PackJson (Join-Path $stagedRoot 'Mods\enabled.json') @($selected.name)
    foreach ($config in $manifest.presets) {
        if ($config.file -notmatch '^[A-Za-z0-9_]+\.json$') { throw 'Nome de preset invalido.' }
        Write-PackJson (Join-Path $stagedRoot ('ModConfigs\' + $config.file)) $config.values
    }
    Test-ProfileFiles $stagedRoot
    [IO.Directory]::Move($stagedRoot, $profileRoot)
}
else {
    Test-ProfileFiles $profileRoot
}

Write-Host "$($selected.Count) mods conferidos. Dados isolados em $profileRoot"
Assert-PackWorldSafety $profileRoot ('TitanWorlds' -in $selected.name)
if ($Modo -in @('Preparar','Verificar')) { return }

if ($Perfil -ne 'Ampliado') {
    Write-Host 'Perfil experimental. Consulte o relatorio de compatibilidade antes de iniciar uma campanha.'
}
$argsTml = @('-nosteam','-tmlsavedirectory',$profileRoot,'-modpath',(Join-Path $profileRoot 'Mods'))
if ($Modo -eq 'Servidor') {
    $ip = $null
    if (-not [Net.IPAddress]::TryParse($Endereco, [ref]$ip)) { throw 'Endereco IP invalido.' }
    $configFile = Join-Path $profileRoot 'serverconfig-rev8.txt'
    if (-not (Test-Path -LiteralPath $configFile)) {
        @(
            "world=$profileRoot\Worlds\Rev8-Expert.wld"
            'autocreate=3'
            'difficulty=1'
            "worldname=Rev8-$Perfil"
            'maxplayers=8'
            'upnp=0'
        ) | Set-Content -LiteralPath $configFile -Encoding UTF8
    }
    $worldSetting = @(Get-Content -LiteralPath $configFile | Where-Object { $_ -match '^\s*world\s*=' })
    if ($worldSetting.Count -gt 1) { throw 'Mais de uma linha world no arquivo de servidor.' }
    if ($worldSetting.Count -eq 1) {
        $worldPath = ($worldSetting[0] -replace '^\s*world\s*=','').Trim()
        if (-not [IO.Path]::IsPathRooted($worldPath)) { $worldPath = Join-Path $tml.Path $worldPath }
        if ('TitanWorlds' -in $selected.name) {
            $allowedWorlds = [IO.Path]::GetFullPath((Join-Path $profileRoot 'Worlds')).TrimEnd('\') + '\'
            if (-not [IO.Path]::GetFullPath($worldPath).StartsWith($allowedWorlds, [StringComparison]::OrdinalIgnoreCase)) {
                throw 'O servidor Titanico deve usar um mundo dentro da pasta Worlds do proprio perfil.'
            }
        }
        Assert-PackWorldFile $worldPath ('TitanWorlds' -in $selected.name)
    }
    $argsTml += @('-server','-config',$configFile,'-ip',$Endereco,'-port',"$Porta",'-noupnp')
}

$serverLock = $null
$lockAcquired = $false
try {
    if ($Modo -eq 'Servidor') {
        $serverLock = [Threading.Mutex]::new($false, 'Local\TerrariaRev8-DedicatedServer')
        try { $lockAcquired = $serverLock.WaitOne(0) }
        catch [Threading.AbandonedMutexException] { $lockAcquired = $true }
        $otherServer = Get-CimInstance Win32_Process | Where-Object {
            ($_.Name -eq 'dotnet.exe' -or $_.Name -match '^tModLoader') -and
            $_.CommandLine -match 'tModLoader' -and $_.CommandLine -match '(?:^|\s)-server(?:\s|$)'
        } | Select-Object -First 1
        if (-not $lockAcquired -or $otherServer) {
            $detail = 'Outro launcher de servidor ainda esta ativo.'
            if ($otherServer) { $detail = "Processo de servidor encontrado: PID $($otherServer.ProcessId)." }
            throw "Feche o outro servidor local de tModLoader. $detail O Subworld Library reutiliza o mesmo canal do Windows; um filho de submundo pode permanecer apos fechar o servidor principal."
        }
    }
    Push-Location $tml.Path
    try {
        # Pass arguments directly so paths with spaces stay intact.
        & $runtime (Join-Path $tml.Path 'tModLoader.dll') @argsTml
        if ($LASTEXITCODE) { throw "O tModLoader terminou com codigo $LASTEXITCODE." }
    }
    finally {
        Pop-Location
    }
}
finally {
    if ($lockAcquired) { $serverLock.ReleaseMutex() }
    if ($serverLock) { $serverLock.Dispose() }
}
