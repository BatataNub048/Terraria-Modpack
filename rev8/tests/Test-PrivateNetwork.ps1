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
}finally{
    Remove-Module PrivateNetwork
    Import-Module (Join-Path $PSScriptRoot '../lib/PrivateNetwork.psm1') -Force
}
foreach($profile in @('Base','Vanity')){
    $port=if($profile -eq 'Vanity'){17791}else{17790}
    $secure=if($profile -eq 'Vanity'){0}else{1}
    foreach($count in @(2,4,8)){
        $lines=@(New-PackFriendServerConfig -World 'Worlds/Test World.wld' -Address '100.64.0.1' -Port $port -Profile $profile -MaxPlayers $count)
        $expected=@('world=Worlds/Test World.wld',"maxplayers=$count",'upnp=0',"port=$port",'ip=100.64.0.1',"secure=$secure")
        if(($lines -join "`n") -cne ($expected -join "`n")){throw "Unexpected config for $profile with $count players."}
        $checks++
    }
}
$launcher=Join-Path $PSScriptRoot '../Servidor-Amigos.ps1'
$command=Get-Command $launcher
$parameter=$command.ScriptBlock.Ast.ParamBlock.Parameters | Where-Object {$_.Name.VariablePath.UserPath -eq 'MaxPlayers'}
if($parameter.DefaultValue.SafeGetValue() -ne 4){throw 'Expected a four-player launcher default.'}
$checks++
foreach($count in @(1,9)){
    $rejected=$false
    try{& $launcher -MaxPlayers $count}catch [System.Management.Automation.ParameterBindingException]{$rejected=$true}
    if(-not $rejected){throw "Launcher accepted out-of-range MaxPlayers: $count"}
    $checks++
}
$errors=@()
foreach($file in @('Servidor-Amigos.ps1','Cliente-Amigo.ps1','lib/PrivateNetwork.psm1','tests/Test-PrivateNetwork.ps1')){
    $tokens=$null;$parseErrors=$null
    $null=[Management.Automation.Language.Parser]::ParseFile((Join-Path $PSScriptRoot ('../'+$file)),[ref]$tokens,[ref]$parseErrors)
    $errors+=@($parseErrors);$checks++
}
if($errors.Count){throw ($errors|Out-String)}
Write-Host "$checks checks passed (PowerShell $($PSVersionTable.PSVersion))."
