#requires -Version 5.1
[CmdletBinding()]
param(
    [ValidateSet('Preparar','Verificar','Servidor','Cliente')][string]$Modo='Servidor',
    [ValidateSet('Base','Vanity')][string]$Perfil='Base',
    [ValidateSet('Tailscale','Local')][string]$Rede='Tailscale',
    [string]$PastaTml=''
)
$ErrorActionPreference='Stop'
Import-Module (Join-Path $PSScriptRoot 'lib/Pack.psm1') -Force
Import-Module (Join-Path $PSScriptRoot 'lib/WorldSafety.psm1') -Force
Import-Module (Join-Path $PSScriptRoot 'lib/PrivateNetwork.psm1') -Force
$name=if($Perfil -eq 'Vanity'){'Experimental-Multiplayer-Vanity'}else{'TodosRecuperados-Titanico-Desempenho'}
$copyName=if($Perfil -eq 'Vanity'){'Experimental-Multiplayer-Vanity'}else{'Amigos-Desempenho'}
$port=if($Perfil -eq 'Vanity'){17791}else{17790}
$manifest=Read-PackJson (Join-Path $PSScriptRoot ('profiles/'+$name+'.lock.json'))
$tml=Get-PackTml $PastaTml
if($tml.Version -ne [version]$manifest.targetTml){throw 'O tModLoader precisa ser exatamente 2026.9.3.1 / Terraria 1.4.4.9.'}
$source=Get-PackPath $PSScriptRoot 'saves/ServidorLocal-Desempenho'
$root=Get-PackPath $PSScriptRoot ('saves/'+$copyName)
$selection=@(Get-PackSelection $manifest 5 @())
$expectedCount=if($Perfil -eq 'Vanity'){72}else{71}
if($selection.Count -ne $expectedCount){throw 'Quantidade de mods divergente.'}
$mutex=$null;$locked=$false
try {
    if($Modo -ne 'Cliente'){
        $mutex=[Threading.Mutex]::new($false,'Local\TerrariaRev8-DedicatedServer')
        try{$locked=$mutex.WaitOne(0)}catch [Threading.AbandonedMutexException]{$locked=$true}
        if(-not $locked){throw 'Outro servidor/launcher Rev8 esta ativo.'}
        Assert-PackGameClosed
    }
    if(-not(Test-Path -LiteralPath $root)){
        if($Modo -ne 'Preparar'){throw 'Primeiro execute -Modo Preparar com todos os jogos fechados.'}
        if(-not(Test-Path -LiteralPath $source)){throw 'Prepare o servidor local existente antes de criar a copia para amigos.'}
        $stage=$root+'.preparando-'+[guid]::NewGuid().ToString('N')
        New-Item -ItemType Directory -Path $stage|Out-Null
        $proof=@()
        foreach($item in Get-ChildItem -LiteralPath $source -Force){
            if($item.Name -like '*.lnk' -or $item.Name -like 'serverconfig*' -or $item.Name -like 'pack-performance-*'){continue}
            if($item.Attributes -band [IO.FileAttributes]::ReparsePoint){throw 'Link inesperado na origem.'}
            foreach($child in @(Get-ChildItem -LiteralPath $item.FullName -Recurse -Force -ErrorAction Stop)){
                if($child.Attributes -band [IO.FileAttributes]::ReparsePoint){throw 'Link inesperado na origem.'}
            }
            Copy-Item -LiteralPath $item.FullName -Destination $stage -Recurse
        }
        foreach($item in Get-ChildItem -LiteralPath $stage -File -Recurse){
            $relative=$item.FullName.Substring($stage.Length+1)
            $hash=Get-PackHash $item.FullName
            if($hash -ne (Get-PackHash (Get-PackPath $source $relative))){throw "Copia divergente: $relative"}
            $proof += [pscustomobject]@{file=$relative;sha256=$hash}
        }
        if($Perfil -eq 'Vanity'){
            $ant=$selection|Where-Object name -eq 'Antisocial'
            $null=Test-PackMod (Join-Path $PSScriptRoot 'payload/Antisocial.tmod') $ant ([version]$manifest.targetTml)
            Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'payload/Antisocial.tmod') -Destination (Join-Path $stage 'Mods/Antisocial.tmod')
            foreach($preset in $manifest.presets|Where-Object {$_.file -in @('Antisocial_ServerConfig.json','MoreAccessories_MoreAccessoriesConfig.json','TooManySlots_TooManySlotsConfig.json')}){
                Write-PackJson (Join-Path $stage ('ModConfigs/'+$preset.file)) $preset.values
            }
        }
        Write-PackJson (Join-Path $stage 'Mods/enabled.json') @($selection.name)
        $config=Read-PackJson (Join-Path $stage 'config.json')
        foreach($pair in @{DisplayWidth=1920;DisplayHeight=1080;Zoom=0.85;AutoSave=$true}.GetEnumerator()){
            $config|Add-Member -NotePropertyName $pair.Key -NotePropertyValue $pair.Value -Force
        }
        Write-PackJson (Join-Path $stage 'config.json') $config
        $worlds=@(Get-ChildItem -LiteralPath (Get-PackPath $stage 'Worlds') -File -Filter '*.wld')
        if($worlds.Count -ne 1){throw 'A origem precisa conter exatamente um mundo local.'}
        $worldId=(Get-PackWorldHeader $worlds[0].FullName).UniqueId.ToString()
        Write-PackJson (Join-Path $stage 'private-clone-origin.json') ([pscustomobject]@{schema=1;profile=$name;worldId=$worldId;source='ServidorLocal-Desempenho';utc=[datetime]::UtcNow;files=$proof})
        [IO.Directory]::Move($stage,$root)
    }
    $enabled=@(Read-PackJson (Join-Path $root 'Mods/enabled.json'))
    $actual=@(Get-ChildItem -LiteralPath (Join-Path $root 'Mods') -Filter '*.tmod' -File)
    if(@(Compare-Object ($selection.name|Sort-Object) ($enabled|Sort-Object)).Count -or
       @(Compare-Object ($selection.name|Sort-Object) ($actual.BaseName|Sort-Object)).Count){throw 'Lista de mods divergente.'}
    $infos=@(foreach($m in $selection){Test-PackMod (Get-PackPath $root ('Mods/'+$m.name+'.tmod')) $m ([version]$manifest.targetTml)})
    Test-PackDependencies $infos $selection
    $origin=Read-PackJson (Join-Path $root 'private-clone-origin.json')
    $worlds=@(Get-ChildItem -LiteralPath (Get-PackPath $root 'Worlds') -File -Filter '*.wld' |
        Where-Object {(Get-PackWorldHeader $_.FullName).UniqueId.ToString() -eq $origin.worldId})
    if($origin.profile -cne $name -or $worlds.Count -ne 1){throw 'Identidade do mundo/perfil divergente.'}
    $world=Get-PackPath $root ('Worlds/'+$worlds[0].Name)
    $players=@(Get-ChildItem -LiteralPath (Get-PackPath $root 'Players') -File -Filter '*.plr')
    if($players.Count -ne 1){throw 'A copia precisa conter exatamente um personagem local.'}
    $player=Get-PackPath $root ('Players/'+$players[0].Name)
    foreach($file in @([IO.Path]::ChangeExtension($world,'.twld'),[IO.Path]::ChangeExtension($player,'.tplr'))){
        if(-not(Test-Path -LiteralPath $file -PathType Leaf)){throw "Save complementar ausente: $file"}
    }
    Assert-PackWorldSafety $root $true
    if($Perfil -eq 'Vanity'){
        foreach($preset in $manifest.presets|Where-Object {$_.file -in @('Antisocial_ServerConfig.json','MoreAccessories_MoreAccessoriesConfig.json','TooManySlots_TooManySlotsConfig.json')}){
            $config=Read-PackJson (Join-Path $root ('ModConfigs/'+$preset.file))
            foreach($property in $preset.values.PSObject.Properties){
                if(-not $config.PSObject.Properties[$property.Name] -or $config.($property.Name) -ne $property.Value){throw "Configuracao experimental divergente: $($preset.file) / $($property.Name)"}
            }
        }
    }
    if($Modo -in @('Preparar','Verificar')){Write-Host "Copia verificada: $copyName ($expectedCount mods).";return}
    $ip=if($Rede -eq 'Local'){'127.0.0.1'}else{Get-PackTailscaleIPv4}
    $runtime=Join-Path $tml.Path 'dotnet/dotnet.exe'
    $arguments=@('-nosteam','-tmlsavedirectory',$root,'-modpath',(Join-Path $root 'Mods'))
    if($Modo -eq 'Servidor'){
        if(Get-NetTCPConnection -State Listen -LocalPort $port -ErrorAction SilentlyContinue){throw 'Porta ja ocupada.'}
        $backup=Get-PackPath $PSScriptRoot ('backups/servidor-amigos/'+$copyName+'/'+[datetime]::UtcNow.ToString('yyyyMMdd-HHmmss-fff'))
        New-Item -ItemType Directory -Path $backup|Out-Null
        foreach($item in Get-ChildItem -LiteralPath $root -Force){
            if($item.Name -in @('Mods','FXC','ResourcePacks') -or $item.Name -like '*.lnk'){continue}
            Copy-Item -LiteralPath $item.FullName -Destination $backup -Recurse
        }
        foreach($item in Get-ChildItem -LiteralPath $backup -File -Recurse){
            $relative=$item.FullName.Substring($backup.Length+1)
            if((Get-PackHash $item.FullName) -ne (Get-PackHash (Get-PackPath $root $relative))){throw 'Falha na verificacao do backup.'}
        }
        $cfg=Get-PackPath $root 'serverconfig-amigos.txt'
        # Terraria only handles secure=1 as an enable switch. A later secure=0 cannot undo it.
        $secure=if($Perfil -eq 'Vanity'){'secure=0'}else{'secure=1'}
        @("world=$world",'maxplayers=2','upnp=0',"port=$port","ip=$ip",$secure)|Set-Content -LiteralPath $cfg -Encoding UTF8
        $arguments+=@('-server','-config',$cfg,'-ip',$ip,'-port',"$port",'-noupnp')
        Write-Host "Servidor de dois jogadores: ${ip}:$port ($Perfil)."
        Write-Host 'Aguarde Listening. Em outro terminal, execute este script com -Modo Cliente e os mesmos -Perfil e -Rede.'
        Write-Host 'Para encerrar, saia dos clientes e digite exit. Aguarde o salvamento. Nao use exit-nosave.'
    }else{
        if(-not(Assert-PackPrivateListener $port $ip $root)){throw 'Servidor deste perfil ainda nao esta pronto.'}
        $clients=@(Get-CimInstance Win32_Process|Where-Object {$_.Name -eq 'dotnet.exe' -and $_.CommandLine -match 'tModLoader\.dll' -and $_.CommandLine -notmatch '(?:^|\s)-server(?:\s|$)'})
        if($clients.Count){throw 'Feche o cliente anterior antes de reconectar.'}
        $path=Join-Path $root 'config.json';$config=Read-PackJson $path
        foreach($pair in @{DisplayWidth=1920;DisplayHeight=1080;Zoom=0.85;AutoSave=$true}.GetEnumerator()){$config|Add-Member -NotePropertyName $pair.Key -NotePropertyValue $pair.Value -Force}
        $temp=$path+'.'+[guid]::NewGuid().ToString('N')+'.tmp'
        Write-PackJson $temp $config
        [IO.File]::Replace($temp,$path,(Join-Path $root 'config.pre-amigos-display.json'))
        $arguments+=@('-join',$ip,'-port',"$port",'-player',$player)
    }
    Push-Location $tml.Path
    try{& $runtime (Join-Path $tml.Path 'tModLoader.dll') @arguments;if($LASTEXITCODE){throw "tModLoader encerrou com codigo $LASTEXITCODE"}}
    finally{Pop-Location}
}finally{if($locked){$mutex.ReleaseMutex()};if($mutex){$mutex.Dispose()}}
