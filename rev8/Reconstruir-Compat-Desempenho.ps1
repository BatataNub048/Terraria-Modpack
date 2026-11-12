#requires -Version 5.1
[CmdletBinding()]
param([string]$PastaTml='')
$ErrorActionPreference='Stop'
Import-Module (Join-Path $PSScriptRoot 'lib/Pack.psm1') -Force
$manifest=Read-PackJson (Join-Path $PSScriptRoot 'profiles/TodosRecuperados-Titanico-Desempenho.lock.json')
$tml=Get-PackTml $PastaTml
if($tml.Version -ne [version]$manifest.targetTml){throw 'A compilacao exige a versao exata de tModLoader do manifest.'}
$source=Get-PackPath $PSScriptRoot 'source/variants/TerrariaPackCompat-1.2.0/TerrariaPackCompat'
if(-not(Test-Path -LiteralPath (Join-Path $source 'build.txt'))){throw 'Fonte do candidato ausente.'}
$build=Get-PackPath $PSScriptRoot ('build/compat-performance-'+[datetime]::UtcNow.ToString('yyyyMMdd-HHmmss')+'-'+[guid]::NewGuid().ToString('N').Substring(0,8))
New-Item -ItemType Directory -Path (Join-Path $build 'Mods') | Out-Null
$selection=@(Get-PackSelection $manifest 5 @())
foreach($mod in $selection){
    $relative=$mod.name+'.tmod'
    if($mod.PSObject.Properties.Name -contains 'payloadFile'){$relative=[string]$mod.payloadFile}
    $payload=Get-PackPath (Join-Path $PSScriptRoot 'payload') $relative
    $null=Test-PackMod $payload $mod ([version]$manifest.targetTml)
    Copy-Item -LiteralPath $payload -Destination (Join-Path $build ('Mods/'+$mod.name+'.tmod'))
}
Write-PackJson (Join-Path $build 'Mods/enabled.json') @($selection.name)
# Keep the audited input as a backup, so an unsuccessful packaging step cannot
# be mistaken for a newly compiled artifact.
Move-Item -LiteralPath (Join-Path $build 'Mods/TerrariaPackCompat.tmod') -Destination (Join-Path $build 'audited-input-TerrariaPackCompat.tmod')
$log=Join-Path $build 'compile.log'
Push-Location $tml.Path
try { & (Join-Path $tml.Path 'dotnet/dotnet.exe') (Join-Path $tml.Path 'tModLoader.dll') -server -nosteam -tmlsavedirectory $build -build $source *> $log }
finally { Pop-Location }
if(-not(Select-String -LiteralPath $log -SimpleMatch 'Compilation finished with 0 errors' -Quiet)){
    throw "Compilacao nao confirmada. Consulte $log"
}
$output=Join-Path $build 'Mods/TerrariaPackCompat.tmod'
if(-not(Test-Path -LiteralPath $output -PathType Leaf)){throw "A compilacao nao produziu um novo pacote. Consulte $log"}
$metadata=[PackTmodReader]::Read($output)
if($metadata.Name -ne 'TerrariaPackCompat' -or $metadata.Version -ne '1.2.0' -or $metadata.BuildTml -ne $manifest.targetTml){throw 'Metadados inesperados no resultado.'}
Write-PackJson (Join-Path $build 'rebuilt-metadata.json') $metadata
Write-Host "Compilado e conferido: $output"
Write-Host 'Nenhum perfil instalado foi substituido. Reaudite o hash e os testes antes de instalar outra compilacao.'
