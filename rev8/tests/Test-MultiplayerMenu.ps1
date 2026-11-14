#requires -Version 5.1
$ErrorActionPreference='Stop'
$fixture=Join-Path ([IO.Path]::GetTempPath()) ('Rev8 menu test '+[guid]::NewGuid().ToString('N'))
$pack=Split-Path -Parent $PSScriptRoot
$settings=Join-Path $fixture 'settings with spaces'
$game=Join-Path $fixture 'game with spaces'
$events=Join-Path $fixture 'events.txt'
$menu=Join-Path $fixture 'Multiplayer-Menu.ps1'
New-Item -ItemType Directory -Path (Join-Path $fixture 'lib'),(Join-Path $game 'dotnet') -Force | Out-Null
New-Item -ItemType File -Path (Join-Path $game 'dotnet/dotnet.exe') | Out-Null
Copy-Item -LiteralPath (Join-Path $pack 'Multiplayer-Menu.ps1'),(Join-Path $pack 'Play Rev8 Multiplayer.bat') -Destination $fixture
@'
function Read-PackJson($Path){[pscustomobject]@{targetTml='2026.9.3.1'}}
function Get-PackTml($Path){[pscustomobject]@{Path=(Join-Path $PSScriptRoot '../game with spaces');Version=[version]'2026.9.3.1'}}
function Get-PackPath($Root,$Relative){Join-Path $Root $Relative}
'@ | Set-Content -LiteralPath (Join-Path $fixture 'lib/Pack.psm1')
@'
function Assert-PackPrivateIPv4($Address){
    if($Address -notin @('100.64.0.1','100.64.0.2')){throw 'Invalid test address'}
    $Address
}
function Get-PackTailscaleIPv4 {
    if(Test-Path -LiteralPath (Join-Path $PSScriptRoot '../offline')){throw 'Tailscale offline'}
    '100.64.0.1'
}
function Assert-PackPrivateListener($Port,$Address,$SaveRoot){
    Test-Path -LiteralPath (Join-Path $PSScriptRoot '../listening')
}
'@ | Set-Content -LiteralPath (Join-Path $fixture 'lib/PrivateNetwork.psm1')
@'
param($Modo,$Perfil,$Rede,$PastaTml,$MaxPlayers)
Add-Content -LiteralPath (Join-Path $PSScriptRoot 'events.txt') "host:$Modo/$Perfil/$Rede/$MaxPlayers"
'@ | Set-Content -LiteralPath (Join-Path $fixture 'Servidor-Amigos.ps1')
@'
param($Modo,$Perfil,$PastaTml,$IpTailscale,[switch]$ConectarAutomaticamente)
Add-Content -LiteralPath (Join-Path $PSScriptRoot 'events.txt') "friend:$Modo/$Perfil/$IpTailscale/$ConectarAutomaticamente"
$path=Join-Path $PSScriptRoot ('saves/ClienteAmigo-'+$Perfil)
if($Modo -eq 'Preparar'){New-Item -ItemType Directory -Path $path -Force | Out-Null}
$broken=Join-Path $PSScriptRoot 'broken'
if($Modo -eq 'Verificar' -and (Test-Path -LiteralPath $broken)){throw 'Hash mismatch'}
if($Modo -eq 'Reparar'){[IO.File]::Delete($broken)}
'@ | Set-Content -LiteralPath (Join-Path $fixture 'Cliente-Amigo.ps1')

function Read-Host($Prompt){
    if(-not $answers.Count){throw "Unexpected prompt: $Prompt"}
    $answers.Dequeue()
}
function Start-Process($FilePath,$ArgumentList,$WorkingDirectory,[switch]$PassThru){
    if($FilePath -notlike '*powershell.exe' -or -not $PassThru){throw 'Unexpected subprocess'}
    Add-Content -LiteralPath $events "spawn:$ArgumentList"
    [pscustomobject]@{HasExited=$false}
}
function Start-Sleep($Seconds){
    Add-Content -LiteralPath $events 'ready'
    New-Item -ItemType File -Path (Join-Path $fixture 'listening') | Out-Null
}
function Invoke-Menu([string[]]$InputLines){
    $answers=[Collections.Generic.Queue[string]]::new()
    foreach($line in $InputLines){$answers.Enqueue($line)}
    & $menu -SettingsDirectory $settings
    if($answers.Count){throw 'Menu left unused simulated inputs.'}
}

try{
    foreach($scriptName in @('Multiplayer-Menu.ps1','Cliente-Amigo.ps1','tests/Test-MultiplayerMenu.ps1')){
        $tokens=$null;$errors=$null
        $null=[Management.Automation.Language.Parser]::ParseFile((Join-Path $pack $scriptName),[ref]$tokens,[ref]$errors)
        if($errors){throw ($errors | Out-String)}
    }
    New-Item -ItemType Directory -Path (Join-Path $fixture 'saves/Experimental-Multiplayer-Vanity') | Out-Null
    Invoke-Menu @('1','','9','','','', '', 'q')
    $lines=@(Get-Content -LiteralPath $events)
    if($lines.Count -ne 3 -or $lines[0] -notmatch 'spawn:.*-ServerProfile Vanity -MaxPlayers 4 -GamePath "[^"]+game with spaces"' -or
       $lines[1] -ne 'ready' -or $lines[2] -ne 'host:Cliente/Vanity/Tailscale/'){
        throw "Unexpected host sequence: $($lines -join ' | ')"
    }
    $invite=Get-Content -LiteralPath (Join-Path $settings 'invite-Vanity.txt')
    if(($invite -join '|') -cne 'Profile: Vanity|Tailscale IPv4: 100.64.0.1|Port: 17791'){throw 'Unexpected invitation contents'}
    Invoke-Menu @('1','','8','','n','','q')
    if(@(Get-Content -LiteralPath $events).Count -ne 3){throw 'Started another server for a ready profile'}
    & $menu -ServerConsole -ServerProfile Base -MaxPlayers 2 -GamePath $game
    if((Get-Content -LiteralPath $events -Tail 1) -ne 'host:Servidor/Base/Tailscale/2'){throw 'Child console did not delegate safely'}

    Invoke-Menu @('2','','y','127.0.0.1','100.64.0.2','','q')
    Invoke-Menu @('2','','','','q')
    $joinEvents=@(Get-Content -LiteralPath $events | Where-Object {$_ -like 'friend:Jogar*'})
    if($joinEvents.Count -ne 2 -or @($joinEvents | Where-Object {$_ -ne 'friend:Jogar/Vanity/100.64.0.2/True'}).Count){throw 'Join did not reuse the saved private IP'}
    if((Get-Content -LiteralPath (Join-Path $settings 'friend-Vanity.txt')) -ne '100.64.0.2'){throw 'Address was not stored locally'}

    New-Item -ItemType File -Path (Join-Path $fixture 'broken') | Out-Null
    Invoke-Menu @('3','','','y','','q')
    if((Get-Content -LiteralPath $events -Tail 1) -ne 'friend:Reparar/Vanity//False'){throw 'Repair was not delegated'}
    New-Item -ItemType File -Path (Join-Path $fixture 'offline') | Out-Null
    $before=@(Get-Content -LiteralPath $events).Count
    Invoke-Menu @('2','','','q')
    if(@(Get-Content -LiteralPath $events).Count -ne $before){throw 'Join proceeded without Tailscale'}

    Push-Location $fixture
    try{
        $output='q' | & $env:ComSpec /d /c '"Play Rev8 Multiplayer.bat"'
        if($LASTEXITCODE -ne 0 -or ($output -join "`n") -notmatch 'Host a Game'){throw 'Double-click entry point failed under CMD'}
    }finally{Pop-Location}
    Write-Host 'PASS: private host readiness, duplicate prevention, invitation, first join, reuse, repair, offline refusal and CMD entry point (simulated).'
}finally{
    $resolved=(Resolve-Path -LiteralPath $fixture).Path
    $prefix=[IO.Path]::GetFullPath((Join-Path ([IO.Path]::GetTempPath()) 'Rev8 menu test '))
    if($resolved -eq [IO.Path]::GetFullPath($fixture) -and $resolved.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase)){
        Remove-Item -LiteralPath $resolved -Recurse -Force
    }
}
