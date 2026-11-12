#requires -Version 5.1
[CmdletBinding()]
param()
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
Import-Module (Join-Path $PSScriptRoot 'lib\Pack.psm1') -Force
$name='TodosRecuperados-Titanico-Desempenho'
$source=Get-PackPath $PSScriptRoot 'saves\TodosRecuperados-Titanico'
$destination=Get-PackPath $PSScriptRoot ('saves\'+$name)
if(Test-Path -LiteralPath $destination){
    & (Join-Path $PSScriptRoot 'Executar-Perfil.ps1') -Perfil $name -Modo Verificar
    return
}
$running=@(Get-CimInstance Win32_Process | Where-Object {
    ($_.Name -eq 'dotnet.exe' -or $_.Name -match '^tModLoader') -and $_.CommandLine -like '*tModLoader*'
})
if($running.Count){throw 'Salve e feche Terraria e todos os servidores antes de clonar a campanha. Nenhum save foi copiado.'}
if(-not(Test-Path -LiteralPath $source -PathType Container)){throw 'Prepare o perfil TodosRecuperados-Titanico primeiro.'}
$manifest=Read-PackJson (Join-Path $PSScriptRoot ('profiles\'+$name+'.lock.json'))
$selected=@(Get-PackSelection $manifest 5 @())
$enabled=@(Read-PackJson (Join-Path $source 'Mods\enabled.json'))
if(@(Compare-Object ($enabled | Sort-Object) ($selected.name | Sort-Object)).Count){throw 'Os mods do perfil de origem mudaram. Reaudite antes de clonar.'}
$stage=Get-PackPath $PSScriptRoot ('saves\'+$name+'.preparando-'+[guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $stage,(Join-Path $stage 'Mods') | Out-Null
# Preserve campaign data in a separate directory; never move or delete the source.
foreach($child in Get-ChildItem -LiteralPath $source -Force){
    if($child.Name -notin @('Mods','serverconfig-rev8.txt')){Copy-Item -LiteralPath $child.FullName -Destination $stage -Recurse}
}
foreach($mod in $selected){
    $relative=$mod.name+'.tmod'
    if($mod.PSObject.Properties.Name -contains 'payloadFile'){$relative=[string]$mod.payloadFile}
    $payload=Get-PackPath (Join-Path $PSScriptRoot 'payload') $relative
    $null=Test-PackMod $payload $mod ([version]$manifest.targetTml)
    Copy-Item -LiteralPath $payload -Destination (Join-Path $stage ('Mods\'+$mod.name+'.tmod'))
}
Write-PackJson (Join-Path $stage 'Mods\enabled.json') @($selected.name)
$dataProof=@()
foreach($folder in @('Worlds','Players','ModConfigs')){
    $originalFolder=Join-Path $source $folder
    if(-not(Test-Path -LiteralPath $originalFolder)){continue}
    foreach($file in Get-ChildItem -LiteralPath $originalFolder -File -Recurse){
        $relative=$file.FullName.Substring($source.Length+1)
        $clone=Get-PackPath $stage $relative
        $hash=Get-PackHash $file.FullName
        if((Get-PackHash $clone) -cne $hash){throw "A copia divergiu: $relative"}
        $dataProof += [pscustomobject]@{file=$relative;sha256=$hash;bytes=$file.Length}
    }
}
Write-PackJson (Join-Path $stage 'clone-origin.json') ([pscustomobject]@{source='TodosRecuperados-Titanico';utc=[datetime]::UtcNow.ToString('o');data=$dataProof})
[IO.Directory]::Move($stage,$destination)
& (Join-Path $PSScriptRoot 'Executar-Perfil.ps1') -Perfil $name -Modo Verificar
Write-Host 'Copia independente criada e conferida. Os quatro perfis anteriores permanecem preservados.'
