#requires -Version 5.1
[CmdletBinding()]
param(
    [ValidateSet('Preparar','Servidor','Cliente','Sessao')][string]$Modo='Servidor',
    [string]$PastaTml='',
    [string]$Mundo='',
    [string]$Personagem='',
    [switch]$SessaoAutomatica
)
$ErrorActionPreference='Stop'
$ProgressPreference='SilentlyContinue'
Import-Module (Join-Path $PSScriptRoot 'lib/Pack.psm1') -Force
Import-Module (Join-Path $PSScriptRoot 'lib/WorldSafety.psm1') -Force
$name='TodosRecuperados-Titanico-Desempenho'
$manifest=Read-PackJson (Join-Path $PSScriptRoot ('profiles/'+$name+'.lock.json'))
$tml=Get-PackTml $PastaTml
if($tml.Version -ne [version]$manifest.targetTml){throw 'Versao do tModLoader diferente da versao auditada.'}
$root=Get-PackPath $PSScriptRoot 'saves/ServidorLocal-Desempenho'
$source=Get-PackPath $PSScriptRoot ('saves/'+$name)
$port=17789
$saveDirs=@('Worlds','Players','VaultSave','CalamityModGlobalSaveData','ModConfigs','ResourcePacks','TrackedMusic')
$saveFiles=@('config.json','input profiles.json','favorites.json','achievements.dat')

function Assert-RegularTree([string]$Path) {
    $pending=[Collections.Generic.Stack[IO.FileSystemInfo]]::new()
    $pending.Push((Get-Item -LiteralPath $Path -Force))
    while($pending.Count){
        $item=$pending.Pop()
        if($item.Attributes -band [IO.FileAttributes]::ReparsePoint){
            throw "Links e juncoes nao sao aceitos na campanha: $($item.FullName)"
        }
        if($item.PSIsContainer){
            foreach($child in Get-ChildItem -LiteralPath $item.FullName -Force){$pending.Push($child)}
        }
    }
}

function Get-SaveName([string]$Directory,[string]$Extension,[string]$Requested,[string]$Option) {
    if($Requested){
        if($Requested -ne [IO.Path]::GetFileName($Requested) -or $Requested -match '[:/\\]' -or
            [IO.Path]::GetExtension($Requested) -ne $Extension){
            throw "Use -$Option com apenas o nome do arquivo $Extension."
        }
        $file=Get-PackPath $Directory $Requested
        if(-not(Test-Path -LiteralPath $file -PathType Leaf)){throw "Arquivo de -$Option ausente: $Requested"}
        return $Requested
    }
    $candidates=@(Get-ChildItem -LiteralPath $Directory -File -Filter ('*'+$Extension))
    if($candidates.Count -ne 1){
        throw "Selecione um arquivo com -$Option. Encontrados: $($candidates.Name -join ', ')"
    }
    return $candidates[0].Name
}

function Copy-CampaignEntries([string]$From,[string]$To,[string[]]$Entries) {
    foreach($entry in $Entries){
        $path=Get-PackPath $From $entry
        if(Test-Path -LiteralPath $path){
            Assert-RegularTree $path
            Copy-Item -LiteralPath $path -Destination $To -Recurse -Force
        }
    }
}

function Get-LocalServer {
    param([int]$LauncherPid=0)
    $listeners=@(Get-NetTCPConnection -LocalPort $port -State Listen -ErrorAction SilentlyContinue)
    if(-not $listeners.Count){return}
    if($listeners.Count -ne 1 -or $listeners[0].LocalAddress -ne '127.0.0.1'){
        throw 'A porta configurada nao esta reservada exclusivamente para o servidor em 127.0.0.1.'
    }
    $process=Get-CimInstance Win32_Process -Filter ('ProcessId='+$listeners[0].OwningProcess)
    $saveArg='(?:^|\s)-tmlsavedirectory\s+"?'+[regex]::Escape($root)+'"?(?:\s|$)'
    if(-not $process -or $process.Name -ne 'dotnet.exe' -or
        $process.CommandLine -notmatch 'tModLoader\.dll' -or
        $process.CommandLine -notmatch '(?:^|\s)-server(?:\s|$)' -or
        $process.CommandLine -match '(?:^|\s)-subworld(?:\s|$)' -or
        $process.CommandLine -notmatch $saveArg -or
        ($LauncherPid -and $process.ParentProcessId -ne $LauncherPid)){
        throw 'A porta configurada pertence a outro processo. A conexao foi cancelada.'
    }
    return $process
}

function Set-LocalClientDisplay {
    $path=Get-PackPath $root 'config.json'
    $config=Read-PackJson $path
    $settings=@{DisplayWidth=1920;DisplayHeight=1080;Zoom=0.85}
    $changed=$false
    foreach($key in $settings.Keys){
        if($config.PSObject.Properties[$key] -and $config.$key -eq $settings[$key]){continue}
        $config | Add-Member -NotePropertyName $key -NotePropertyValue $settings[$key] -Force
        $changed=$true
    }
    if($changed){
        $temporary=$path+'.'+[guid]::NewGuid().ToString('N')+'.tmp'
        Write-PackJson $temporary $config
        $previous=Get-PackPath $root 'config.pre-local-display.json'
        [IO.File]::Replace($temporary,$path,$previous)
    }
}

$mutex=$null
$locked=$false
try {
if($Modo -in @('Sessao','Servidor','Cliente')){
    $mutexName=switch($Modo){
        'Sessao' {'TerrariaRev8-LocalSession'}
        'Servidor' {'TerrariaRev8-DedicatedServer'}
        'Cliente' {'TerrariaRev8-LocalClient'}
    }
    $mutex=[Threading.Mutex]::new($false,('Local\'+$mutexName))
    try{$locked=$mutex.WaitOne(0)}catch [Threading.AbandonedMutexException]{$locked=$true}
    if(-not $locked){throw 'Ja existe um launcher deste tipo em execucao.'}
}
if($Modo -in @('Sessao','Servidor')){
    Assert-PackGameClosed
    if(Get-NetTCPConnection -LocalPort $port -State Listen -ErrorAction SilentlyContinue){throw 'A porta do servidor local ja esta ocupada.'}
}
if(-not(Test-Path -LiteralPath $root)){
    if($Modo -eq 'Cliente'){throw 'Prepare e inicie o servidor antes de abrir o cliente.'}
    Assert-PackGameClosed
    & (Join-Path $PSScriptRoot 'Executar-Perfil.ps1') -Perfil $name -Modo Verificar -PastaTml $tml.Path
    $Mundo=Get-SaveName (Get-PackPath $source 'Worlds') '.wld' $Mundo 'Mundo'
    $Personagem=Get-SaveName (Get-PackPath $source 'Players') '.plr' $Personagem 'Personagem'
    $stage=$root+'.preparando-'+[guid]::NewGuid().ToString('N')
    New-Item -ItemType Directory -Path $stage | Out-Null
    Copy-CampaignEntries $source $stage ($saveDirs+$saveFiles+@('Mods'))
    $proof=@(foreach($item in Get-ChildItem -LiteralPath $stage -File -Recurse){
        $rel=$item.FullName.Substring($stage.Length+1);$hash=Get-PackHash $item.FullName
        if($hash -ne (Get-PackHash (Join-Path $source $rel))){throw "Copia divergente: $rel"}
        [pscustomobject]@{file=$rel;sha256=$hash}
    })
    $stagedWorld=Get-PackPath $stage ('Worlds/'+$Mundo)
    $worldId=(Get-PackWorldHeader $stagedWorld).UniqueId.ToString()
    foreach($path in @([IO.Path]::ChangeExtension($stagedWorld,'.twld'), (Get-PackPath $stage ('Players/'+[IO.Path]::ChangeExtension($Personagem,'.tplr'))))){
        if(-not(Test-Path -LiteralPath $path -PathType Leaf)){throw "Dados de mods da campanha ausentes: $path"}
    }
    Write-PackJson (Join-Path $stage 'server-clone-origin.json') ([pscustomobject]@{utc=[datetime]::UtcNow;source=$name;worldFile=$Mundo;playerFile=$Personagem;worldId=$worldId;files=$proof})
    [IO.Directory]::Move($stage,$root)
}
$selection=@(Get-PackSelection $manifest 5 @())
if($selection.Count -ne 71){throw 'O perfil de desempenho precisa ter 71 mods.'}
$modsPath=Get-PackPath $root 'Mods'
Assert-RegularTree $modsPath
$enabled=@(Read-PackJson (Get-PackPath $modsPath 'enabled.json'))
if(@(Compare-Object ($selection.name|Sort-Object) ($enabled|Sort-Object)).Count){throw 'Lista de mods divergiu.'}
$actual=@(Get-ChildItem -LiteralPath $modsPath -File -Filter '*.tmod')
if(@(Compare-Object ($selection.name|Sort-Object) ($actual.BaseName|Sort-Object)).Count){throw 'Arquivos de mods ausentes ou extras.'}
$infos=@(foreach($m in $selection){Test-PackMod (Get-PackPath $modsPath ($m.name+'.tmod')) $m ([version]$manifest.targetTml)})
Test-PackDependencies $infos $selection
$cfg=Get-PackPath $root 'serverconfig-local.txt'
$originPath=Get-PackPath $root 'server-clone-origin.json'
$origin=Read-PackJson $originPath
if($origin.source -cne $name){throw 'A origem da copia nao corresponde ao perfil de desempenho.'}
$upgrade=(-not $origin.worldFile -or -not $origin.playerFile -or -not $origin.worldId)
if($upgrade){
    if($Modo -eq 'Cliente'){throw 'A copia precisa ser validada pelo launcher do servidor.'}
    Assert-PackGameClosed
}else{
    if(($Mundo -and $Mundo -ne $origin.worldFile) -or ($Personagem -and $Personagem -ne $origin.playerFile)){
        throw 'Esta copia ja tem mundo e personagem selecionados. Preserve-a antes de criar outra sessao.'
    }
    $Mundo=$origin.worldFile
    $Personagem=$origin.playerFile
}
$Mundo=Get-SaveName (Get-PackPath $root 'Worlds') '.wld' $Mundo 'Mundo'
$Personagem=Get-SaveName (Get-PackPath $root 'Players') '.plr' $Personagem 'Personagem'
$world=Get-PackPath $root ('Worlds/'+$Mundo)
$player=Get-PackPath $root ('Players/'+$Personagem)
if(Test-Path -LiteralPath $cfg){
    $worldLines=@(Get-Content -LiteralPath $cfg | Where-Object {$_ -match '^\s*world\s*='})
    if($worldLines.Count -ne 1){throw 'A configuracao do servidor precisa indicar exatamente um mundo.'}
    $configuredWorld=($worldLines[0] -replace '^\s*world\s*=','').Trim()
    if(-not [IO.Path]::IsPathRooted($configuredWorld) -or [IO.Path]::GetFullPath($configuredWorld) -ne $world){
        throw 'O mundo configurado nao pertence a esta copia do perfil de desempenho.'
    }
}
Assert-PackWorldSafety $root $true
Assert-PackWorldFile $world $true
foreach($path in @((Get-PackPath $root ('Worlds/'+[IO.Path]::ChangeExtension($Mundo,'.twld'))), (Get-PackPath $root ('Players/'+[IO.Path]::ChangeExtension($Personagem,'.tplr'))))){
    if(-not(Test-Path -LiteralPath $path -PathType Leaf)){throw "Dados de mods da campanha ausentes: $path"}
}
$worldId=(Get-PackWorldHeader $world).UniqueId.ToString()
if($origin.worldId -and $worldId -ne $origin.worldId){throw 'O identificador do mundo diverge da campanha copiada.'}
if($upgrade){
    $sourceWorld=Get-PackPath $source ('Worlds/'+$Mundo)
    if(-not $origin.worldId -and $worldId -ne (Get-PackWorldHeader $sourceWorld).UniqueId.ToString()){
        throw 'O identificador do mundo diverge do mundo original do perfil.'
    }
    $origin | Add-Member -NotePropertyName worldId -NotePropertyValue $worldId -Force
    $origin | Add-Member -NotePropertyName worldFile -NotePropertyValue $Mundo -Force
    $origin | Add-Member -NotePropertyName playerFile -NotePropertyValue $Personagem -Force
    $originTemp=$originPath+'.'+[guid]::NewGuid().ToString('N')+'.tmp'
    Write-PackJson $originTemp $origin
    [IO.File]::Replace($originTemp,$originPath,(Get-PackPath $root 'server-clone-origin.pre-world-id.json'))
}
if($Modo -eq 'Preparar'){Write-Host "Copia independente pronta: $root";return}
$runtime=Join-Path $tml.Path 'dotnet/dotnet.exe'
if(-not(Test-Path -LiteralPath $runtime -PathType Leaf)){throw 'Runtime do tModLoader nao encontrado.'}
if($Modo -eq 'Sessao'){
    $ps=Join-Path ([Environment]::SystemDirectory) 'WindowsPowerShell/v1.0/powershell.exe'
    $childArgs='-NoProfile -ExecutionPolicy Bypass -File "'+$PSCommandPath+'" -Modo Servidor -SessaoAutomatica -PastaTml "'+$tml.Path+'"'
    $server=Start-Process -FilePath $ps -ArgumentList $childArgs -PassThru
    $wait=[Diagnostics.Stopwatch]::StartNew()
    Write-Host 'Aguardando o servidor carregar o mundo e abrir a porta local...'
    while(-not (Get-LocalServer -LauncherPid $server.Id)){
        if($server.HasExited){throw "O servidor encerrou antes de ficar pronto. Codigo: $($server.ExitCode)."}
        if($wait.Elapsed.TotalMinutes -ge 10){throw 'O servidor nao ficou pronto em dez minutos. Confira o console do servidor.'}
        Start-Sleep -Milliseconds 750
    }
    & $PSCommandPath -Modo Cliente -PastaTml $tml.Path
    Write-Host 'O cliente fechou. Digite exit no console do servidor e aguarde o salvamento.'
    return
}
$arguments=@('-nosteam','-tmlsavedirectory',$root,'-modpath',$modsPath)
if($Modo -eq 'Servidor'){
    $backup=Get-PackPath $PSScriptRoot ('backups/servidor-local/'+[datetime]::UtcNow.ToString('yyyyMMdd-HHmmss-fff'))
    $backupStage=$backup+'.preparando-'+[guid]::NewGuid().ToString('N')
    New-Item -ItemType Directory -Path $backupStage -Force|Out-Null
    Copy-CampaignEntries $root $backupStage ($saveDirs+$saveFiles+@('server-clone-origin.json'))
    [IO.Directory]::Move($backupStage,$backup)
    @("world=$world",'maxplayers=2','upnp=0',"port=$port")|Set-Content -LiteralPath $cfg -Encoding utf8
    Write-Host 'Servidor acessivel somente neste PC.'
    if($SessaoAutomatica){Write-Host 'O cliente abrira automaticamente quando o servidor estiver pronto.'}
    else{Write-Host 'Depois de Listening, abra JOGAR-NO-SERVIDOR-LOCAL.bat.'}
    Write-Host 'Para encerrar: saia do cliente e digite exit nesta janela. Aguarde o salvamento terminar.'
    $arguments+=@('-server','-config',$cfg,'-ip','127.0.0.1','-port',"$port",'-noupnp')
}else{
    if(-not(Get-LocalServer)){throw 'Abra INICIAR-SERVIDOR-LOCAL.bat e aguarde Listening antes de conectar.'}
    $runningClients=@(Get-CimInstance Win32_Process|Where-Object{$_.Name -eq 'dotnet.exe' -and $_.CommandLine -like '*tModLoader.dll*' -and $_.CommandLine -notmatch '(?:^|\s)-server(?:\s|$)'})
    if($runningClients.Count){throw 'Ja existe um cliente de tModLoader aberto.'}
    Set-LocalClientDisplay
    $arguments+=@('-join','127.0.0.1','-port',"$port",'-player',$player)
}
Push-Location $tml.Path
try{& $runtime (Join-Path $tml.Path 'tModLoader.dll') @arguments;if($LASTEXITCODE){throw "tModLoader encerrou com codigo $LASTEXITCODE"}}
finally{Pop-Location}
}
finally{
    if($locked){$mutex.ReleaseMutex()}
    if($mutex){$mutex.Dispose()}
}
