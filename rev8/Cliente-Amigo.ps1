#requires -Version 5.1
[CmdletBinding()]
param(
    [ValidateSet('Preparar','Verificar','Jogar')][string]$Modo='Jogar',
    [ValidateSet('Base','Vanity')][string]$Perfil='Base',
    [string]$IpTailscale='',
    [string]$PastaTml=''
)
$ErrorActionPreference='Stop'
Import-Module (Join-Path $PSScriptRoot 'lib/Pack.psm1') -Force
Import-Module (Join-Path $PSScriptRoot 'lib/PrivateNetwork.psm1') -Force
$name=if($Perfil -eq 'Vanity'){'Experimental-Multiplayer-Vanity'}else{'TodosRecuperados-Titanico-Desempenho'}
$port=if($Perfil -eq 'Vanity'){17791}else{17790}
$manifest=Read-PackJson (Join-Path $PSScriptRoot ('profiles/'+$name+'.lock.json'))
$tml=Get-PackTml $PastaTml
if($tml.Version -ne [version]$manifest.targetTml){throw 'Instale a versao exata 2026.9.3.1 do tModLoader para Terraria 1.4.4.9.'}
$selection=@(Get-PackSelection $manifest 5 @())
$count=if($Perfil -eq 'Vanity'){72}else{71}
if($selection.Count -ne $count){throw 'Selecao divergente.'}
$root=Get-PackPath $PSScriptRoot ('saves/ClienteAmigo-'+$Perfil)
$mutex=[Threading.Mutex]::new($false,'Local\TerrariaRev8-FriendClient');$locked=$false
try{
    try{$locked=$mutex.WaitOne(0)}catch [Threading.AbandonedMutexException]{$locked=$true}
    if(-not $locked){throw 'Outro launcher do cliente esta ativo.'}
    Assert-PackGameClosed
    if(-not(Test-Path -LiteralPath $root)){
        if($Modo -ne 'Preparar'){throw 'Execute primeiro -Modo Preparar.'}
        $resolved=@{}
        foreach($m in $selection){
            $relative=$m.name+'.tmod'
            if($m.PSObject.Properties['payloadFile']){$relative=$m.payloadFile}
            $path=Get-PackPath (Join-Path $PSScriptRoot 'payload') $relative
            if($m.name -eq 'Antisocial' -and -not(Test-Path -LiteralPath $path)){
                $cache=Get-PackPath $PSScriptRoot 'cache-amigo'
                $report=Get-PackPath $PSScriptRoot ('evidence/download-antisocial-'+[datetime]::UtcNow.ToString('yyyyMMdd-HHmmss'))
                New-Item -ItemType Directory -Path $cache,$report -Force|Out-Null
                $download=Invoke-PackDownloads @($m) $cache $report
                if(-not $download.Receipts[$m.workshopId]){throw 'Steam nao confirmou o download oficial do Antisocial.'}
                $found=Find-PackMod (Join-Path $cache ('steamcmd/steamapps/workshop/content/1281930/'+$m.workshopId)) $m ([version]$manifest.targetTml)
                $path=$found.Path
            }
            $resolved[$m.name]=(Test-PackMod $path $m ([version]$manifest.targetTml)).Path
        }
        $stage=$root+'.preparando-'+[guid]::NewGuid().ToString('N')
        New-Item -ItemType Directory -Path (Join-Path $stage 'Mods'),(Join-Path $stage 'ModConfigs'),(Join-Path $stage 'Players'),(Join-Path $stage 'Worlds') -Force|Out-Null
        foreach($m in $selection){Copy-Item -LiteralPath $resolved[$m.name] -Destination (Join-Path $stage ('Mods/'+$m.name+'.tmod'))}
        $configSource=Join-Path $PSScriptRoot 'configuracoes/TodosRecuperados-Titanico-Desempenho'
        if(-not(Test-Path -LiteralPath $configSource)){$configSource=Join-Path $PSScriptRoot 'configuracoes'}
        foreach($config in Get-ChildItem -LiteralPath $configSource -Filter '*.json' -File){Copy-Item -LiteralPath $config.FullName -Destination (Join-Path $stage 'ModConfigs')}
        foreach($preset in $manifest.presets){
            $path=Join-Path $stage ('ModConfigs/'+$preset.file)
            $value=if(Test-Path -LiteralPath $path){Read-PackJson $path}else{[pscustomobject]@{}}
            foreach($p in $preset.values.PSObject.Properties){$value|Add-Member -NotePropertyName $p.Name -NotePropertyValue $p.Value -Force}
            Write-PackJson $path $value
        }
        Write-PackJson (Join-Path $stage 'Mods/enabled.json') @($selection.name)
        Write-PackJson (Join-Path $stage 'config.json') ([pscustomobject]@{DisplayWidth=1920;DisplayHeight=1080;Zoom=0.85;AutoSave=$true})
        [IO.Directory]::Move($stage,$root)
    }
    $enabled=@(Read-PackJson (Join-Path $root 'Mods/enabled.json'))
    $actual=@(Get-ChildItem -LiteralPath (Join-Path $root 'Mods') -Filter '*.tmod' -File)
    if(@(Compare-Object ($selection.name|Sort-Object) ($enabled|Sort-Object)).Count -or @(Compare-Object ($selection.name|Sort-Object) ($actual.BaseName|Sort-Object)).Count){throw 'Mods locais divergentes.'}
    $infos=@(foreach($m in $selection){Test-PackMod (Get-PackPath $root ('Mods/'+$m.name+'.tmod')) $m ([version]$manifest.targetTml)})
    Test-PackDependencies $infos $selection
    if($Perfil -eq 'Vanity'){
        foreach($preset in $manifest.presets|Where-Object {$_.file -in @('Antisocial_ServerConfig.json','MoreAccessories_MoreAccessoriesConfig.json','TooManySlots_TooManySlotsConfig.json')}){
            $actualConfig=Read-PackJson (Join-Path $root ('ModConfigs/'+$preset.file))
            foreach($p in $preset.values.PSObject.Properties){if(-not $actualConfig.PSObject.Properties[$p.Name] -or $actualConfig.($p.Name) -ne $p.Value){throw ('Configuracao experimental divergente: '+$p.Name)}}
        }
    }
    if($Modo -ne 'Jogar'){Write-Host "Cliente pronto: $count mods, $Perfil. Crie seu proprio personagem ao abrir o jogo.";return}
    $localIp=Get-PackTailscaleIPv4
    $ip=Assert-PackPrivateIPv4 $IpTailscale
    $backup=Get-PackPath $PSScriptRoot ('backups/cliente-amigo/'+$Perfil+'/'+[datetime]::UtcNow.ToString('yyyyMMdd-HHmmss-fff'))
    New-Item -ItemType Directory -Path $backup|Out-Null
    foreach($item in Get-ChildItem -LiteralPath $root -Force){
        if($item.Name -in @('Mods','FXC','ResourcePacks') -or $item.Name -like '*.lnk'){continue}
        Copy-Item -LiteralPath $item.FullName -Destination $backup -Recurse
    }
    $configPath=Join-Path $root 'config.json';$config=Read-PackJson $configPath
    foreach($pair in @{DisplayWidth=1920;DisplayHeight=1080;Zoom=0.85;AutoSave=$true}.GetEnumerator()){$config|Add-Member -NotePropertyName $pair.Key -NotePropertyValue $pair.Value -Force}
    Write-PackJson $configPath $config
    Write-Host "Entre em Multiplayer > Join via IP: $ip / $port. Use um personagem com nome diferente do anfitriao."
    Push-Location $tml.Path
    try{& (Join-Path $tml.Path 'dotnet/dotnet.exe') (Join-Path $tml.Path 'tModLoader.dll') -nosteam -tmlsavedirectory $root -modpath (Join-Path $root 'Mods');if($LASTEXITCODE){throw "Cliente encerrou com codigo $LASTEXITCODE"}}
    finally{Pop-Location}
}finally{if($locked){$mutex.ReleaseMutex()};$mutex.Dispose()}
