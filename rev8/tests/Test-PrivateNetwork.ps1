#requires -Version 5.1
$ErrorActionPreference='Stop'
Import-Module (Join-Path $PSScriptRoot '../lib/PrivateNetwork.psm1') -Force
$checks=0
foreach($ip in @('100.64.0.1','100.127.255.254')){
    if((Assert-PackPrivateIPv4 $ip) -ne $ip){throw "Valid address rejected: $ip"};$checks++
}
foreach($ip in @('0.0.0.0','127.0.0.1','192.168.1.1','8.8.8.8','100.63.255.255','100.128.0.0','::','::1','example.com','100.64.0.1;exit','')){
    $rejected=$false
    try{$null=Assert-PackPrivateIPv4 $ip}catch{$rejected=$true}
    if(-not $rejected){throw "Unsafe address accepted: $ip"};$checks++
}
$module=Get-Module PrivateNetwork
& $module {
    function script:Get-NetTCPConnection {param($LocalPort,$State,$ErrorAction) [pscustomobject]@{LocalAddress='0.0.0.0';OwningProcess=123}}
}
try{
    $rejected=$false
    try{$null=Assert-PackPrivateListener 17790 '100.64.0.1' 'C:\disposable'}catch{$rejected=$true}
    if(-not $rejected){throw 'Wildcard listener accepted.'};$checks++
}finally{Remove-Module PrivateNetwork}
$errors=@()
foreach($file in @('Servidor-Amigos.ps1','Cliente-Amigo.ps1','lib/PrivateNetwork.psm1')){
    $tokens=$null;$parseErrors=$null
    $null=[Management.Automation.Language.Parser]::ParseFile((Join-Path $PSScriptRoot ('../'+$file)),[ref]$tokens,[ref]$parseErrors)
    $errors+=@($parseErrors);$checks++
}
if($errors.Count){throw ($errors|Out-String)}
Write-Host "$checks checks passed (PowerShell $($PSVersionTable.PSVersion))."
