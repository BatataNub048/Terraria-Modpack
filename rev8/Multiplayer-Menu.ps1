#requires -Version 5.1
[CmdletBinding()]
param(
    [string]$SettingsDirectory=(Join-Path ([Environment]::GetFolderPath('LocalApplicationData')) 'TerrariaRev8/Multiplayer'),
    [switch]$ServerConsole,
    [ValidateSet('Base','Vanity')][string]$ServerProfile='Vanity',
    [ValidateRange(2,8)][int]$MaxPlayers=4,
    [string]$GamePath,
    [string]$FailureMarker
)
$ErrorActionPreference='Stop'
$serverScript=Join-Path $PSScriptRoot 'Servidor-Amigos.ps1'
if($ServerConsole){
    try{& $serverScript -Modo Servidor -Rede Tailscale -Perfil $ServerProfile -MaxPlayers $MaxPlayers -PastaTml $GamePath}
    catch{
        if($FailureMarker){[IO.File]::WriteAllText($FailureMarker,'Server startup failed.')}
        Write-Host ('Server error: '+$_.Exception.Message) -ForegroundColor Red
        [void](Read-Host 'Press Enter to close this server window')
        exit 1
    }
    return
}
Import-Module (Join-Path $PSScriptRoot 'lib/Pack.psm1') -Force
Import-Module (Join-Path $PSScriptRoot 'lib/PrivateNetwork.psm1') -Force

$menuScript=$PSCommandPath
$localData=$SettingsDirectory
$friendScript=Join-Path $PSScriptRoot 'Cliente-Amigo.ps1'
$powershell=Join-Path $PSHOME 'powershell.exe'

function Read-Choice([string]$Prompt,[string[]]$Allowed,[string]$Default=''){
    while($true){
        $answer=([string](Read-Host $Prompt)).Trim()
        if(-not $answer){$answer=$Default}
        if($answer -in $Allowed){return $answer}
        Write-Host ('Choose '+($Allowed -join ', ')+'.') -ForegroundColor Yellow
    }
}

function Select-Profile {
    if((Read-Choice 'Profile: 1 Vanity (72 mods, default), 2 Base (71 mods)' @('1','2') '1') -eq '2'){
        return @{Name='Base';Port=17790;ServerSave='Amigos-Desempenho'}
    }
    return @{Name='Vanity';Port=17791;ServerSave='Experimental-Multiplayer-Vanity'}
}

function Resolve-Game([string]$Profile){
    $manifestName=if($Profile -eq 'Vanity'){'Experimental-Multiplayer-Vanity'}else{'TodosRecuperados-Titanico-Desempenho'}
    $required=[version](Read-PackJson (Join-Path $PSScriptRoot ('profiles/'+$manifestName+'.lock.json'))).targetTml
    $pathFile=Join-Path $localData 'tmodloader-path.txt'
    try{
        $saved=if(Test-Path -LiteralPath $pathFile){(Get-Content -LiteralPath $pathFile -Raw).Trim()}else{''}
        $detected=Get-PackTml $saved
        if($detected.Version -ne $required){throw "Found tModLoader $($detected.Version). This profile requires $required."}
    }catch{
        Write-Host $_.Exception.Message -ForegroundColor Yellow
        Write-Host "Install Terraria and tModLoader $required, run tModLoader once, then close it."
        Write-Host 'For an official archived installation, paste the folder containing tModLoader.dll.'
        $selected=Read-PackTmlPath $required
        $detected=Get-PackTml $selected
    }
    if(-not(Test-Path -LiteralPath (Join-Path $detected.Path 'dotnet/dotnet.exe') -PathType Leaf)){
        throw 'The tModLoader runtime is missing. Start the correct installation once and close it.'
    }
    New-Item -ItemType Directory -Path $localData -Force | Out-Null
    Set-Content -LiteralPath $pathFile -Value $detected.Path -Encoding UTF8
    return $detected.Path
}

function Confirm-Setup($Profile,[string]$GamePath,[bool]$Hosting,[switch]$OfferRepair){
    if($Hosting){
        $path=Get-PackPath $PSScriptRoot ('saves/'+$Profile.ServerSave)
        $scriptPath=$serverScript
        $prepareHelp='Prepare the separate friends copy from the existing solo-server copy?'
    }else{
        $path=Get-PackPath $PSScriptRoot ('saves/ClienteAmigo-'+$Profile.Name)
        $scriptPath=$friendScript
        $prepareHelp='Prepare the friend profile from the authorized local package?'
    }
    if(Test-Path -LiteralPath $path){
        # The existing host and friend launch commands audit the profile themselves.
        if(-not $OfferRepair){return}
        try{& $scriptPath -Modo Verificar -Perfil $Profile.Name -PastaTml $GamePath}
        catch{
            if($Hosting){throw}
            Write-Host $_.Exception.Message -ForegroundColor Yellow
            Write-Host 'Close the game first. Repair reuses audited files and keeps the previous friend profile as a backup.'
            if((Read-Choice 'Repair the friend profile now? [y/N]' @('y','n') 'n') -ne 'y'){throw}
            & $scriptPath -Modo Reparar -Perfil $Profile.Name -PastaTml $GamePath
        }
        return
    }
    if(-not $Hosting){
        Write-Host 'Use the exact Rev8 artifacts in the payload folder or install the Workshop items listed in the guide.'
        Write-Host 'Local Workshop copies must match the lock. GitHub supplies scripts and manifests. See MULTIPLAYER-E-VANITY.md.'
    }else{
        Write-Host 'Host setup needs a prepared ServidorLocal-Desempenho copy with one local world and character, and the audited Vanity payload.'
    }
    if((Read-Choice "$prepareHelp [y/N]" @('y','n') 'n') -ne 'y'){
        throw 'Setup cancelled. See MULTIPLAYER-E-VANITY.md for prerequisites.'
    }
    & $scriptPath -Modo Preparar -Perfil $Profile.Name -PastaTml $GamePath
}

function Read-FriendAddress([string]$Profile){
    $file=Join-Path $localData ('friend-'+$Profile+'.txt')
    $saved=''
    if(Test-Path -LiteralPath $file){
        try{$saved=Assert-PackPrivateIPv4 ((Get-Content -LiteralPath $file -Raw).Trim())}
        catch{Write-Host 'The saved address is invalid. Enter the host IPv4 again.' -ForegroundColor Yellow}
    }
    while($true){
        $answer=[string]$(if($saved){Read-Host "Host Tailscale IPv4 (Enter to reuse $saved, or type a new IP)"}else{Read-Host 'Host Tailscale IPv4 (from the invitation, Q to go back)'})
        if($answer -eq 'q'){throw 'Join cancelled.'}
        if(-not $answer.Trim()){$answer=$saved}
        try{$address=Assert-PackPrivateIPv4 ($answer.Trim())}
        catch{Write-Host $_.Exception.Message -ForegroundColor Yellow;continue}
        Set-Content -LiteralPath $file -Value $address -Encoding ASCII
        return $address
    }
}

function Start-Hosting($Profile,[string]$GamePath,[string]$Address){
    $count=Read-Choice 'Total players including host [4]: 2-8' @('2','3','4','5','6','7','8') '4'
    $serverRoot=Get-PackPath $PSScriptRoot ('saves/'+$Profile.ServerSave)
    if(Assert-PackPrivateListener $Profile.Port $Address $serverRoot){
        Write-Host 'This server is already running.'
    }else{
        Confirm-Setup $Profile $GamePath $true
        $failure=Join-Path $localData ('server-failed-'+[guid]::NewGuid().ToString('N')+'.txt')
        $quotedGamePath='"'+($GamePath -replace '\\$','\\')+'"'
        $argsLine='-NoProfile -ExecutionPolicy Bypass -File "'+$menuScript+'" -ServerConsole -ServerProfile '+$Profile.Name+' -MaxPlayers '+$count+' -GamePath '+$quotedGamePath+' -FailureMarker "'+$failure+'"'
        $process=Start-Process -FilePath $powershell -ArgumentList $argsLine -WorkingDirectory $PSScriptRoot -PassThru
        $timer=[Diagnostics.Stopwatch]::StartNew()
        Write-Host "Waiting for the private server at ${Address}:$($Profile.Port). See the server window for startup progress."
        while($true){
            if(Test-Path -LiteralPath $failure){
                [IO.File]::Delete($failure)
                throw 'The server did not start. Read the error in its window.'
            }
            if($process.HasExited){throw 'The server window closed before the server was ready.'}
            if(Assert-PackPrivateListener $Profile.Port $Address $serverRoot){break}
            if($timer.Elapsed.TotalMinutes -ge 5){throw 'The server did not become ready in five minutes. Check its window before trying again.'}
            Start-Sleep -Seconds 1
        }
    }
    $invite=Join-Path $localData ('invite-'+$Profile.Name+'.txt')
    $details=@("Profile: $($Profile.Name)","Tailscale IPv4: $Address","Port: $($Profile.Port)")
    $details | Set-Content -LiteralPath $invite -Encoding ASCII
    $details | ForEach-Object {Write-Host $_}
    Write-Host "Share these connection details or send this file yourself: $invite"
    if((Read-Choice 'Open the invitation file now? [y/N]' @('y','n') 'n') -eq 'y'){
        Start-Process -FilePath (Join-Path $env:SystemRoot 'System32/notepad.exe') -ArgumentList ('"'+$invite+'"')
    }
    if((Read-Choice 'Open your game now? [Y/n]' @('y','n') 'y') -eq 'y'){
        & $serverScript -Modo Cliente -Perfil $Profile.Name -Rede Tailscale -PastaTml $GamePath
    }
}

while($true){
    Write-Host ''
    Write-Host 'Terraria Rev8 Multiplayer'
    Write-Host '1 - Host a Game'
    Write-Host '2 - Join a Friend'
    Write-Host '3 - Check / Repair Setup'
    Write-Host 'Q - Quit'
    $action=Read-Choice 'Choose an option' @('1','2','3','q')
    if($action -eq 'q'){break}
    try{
        $selectedProfile=Select-Profile
        if($action -eq '3'){
            Write-Host 'Install Tailscale and sign in. The host shares only the server machine and allows the selected TCP port.'
            Write-Host 'See MULTIPLAYER-E-VANITY.md for authorized mod sources and repair steps.'
            try{Write-Host "Tailscale connected: $(Get-PackTailscaleIPv4)"}
            catch{Write-Host $_.Exception.Message -ForegroundColor Yellow}
            $hostSetup=(Read-Choice 'Check: 1 Host, 2 Friend (default)' @('1','2') '2') -eq '1'
            $game=Resolve-Game $selectedProfile.Name
            Confirm-Setup $selectedProfile $game $hostSetup -OfferRepair
        }else{
            $address=Get-PackTailscaleIPv4
            $game=Resolve-Game $selectedProfile.Name
            if($action -eq '1'){Start-Hosting $selectedProfile $game $address}
            else{
                Confirm-Setup $selectedProfile $game $false
                $hostAddress=Read-FriendAddress $selectedProfile.Name
                & $friendScript -Modo Jogar -Perfil $selectedProfile.Name -IpTailscale $hostAddress -PastaTml $game -ConectarAutomaticamente
            }
        }
    }catch{
        Write-Host ("Error: "+$_.Exception.Message) -ForegroundColor Red
        Write-Host 'Use Check / Repair Setup or see MULTIPLAYER-E-VANITY.md. Existing profiles are preserved on validation errors.'
    }
    [void](Read-Host 'Press Enter to return to the menu')
}
