#requires -Version 5.1
Set-StrictMode -Version Latest

function Assert-PackPrivateIPv4([string]$Address) {
    $ip=$null
    if(-not [Net.IPAddress]::TryParse($Address,[ref]$ip) -or $ip.AddressFamily -ne [Net.Sockets.AddressFamily]::InterNetwork){throw 'Informe um IPv4 do Tailscale.'}
    $b=$ip.GetAddressBytes()
    if($b[0] -ne 100 -or $b[1] -lt 64 -or $b[1] -gt 127){throw 'Endereco fora da faixa IPv4 do Tailscale (100.64.0.0/10).'}
    return $ip.ToString()
}

function Get-PackTailscaleIPv4 {
    $exe=Join-Path $env:ProgramFiles 'Tailscale/tailscale.exe'
    if(-not(Test-Path -LiteralPath $exe)){
        $command=Get-Command tailscale.exe -ErrorAction SilentlyContinue
        if(-not $command){throw 'Instale e conecte o Tailscale manualmente. Nenhuma interface alternativa sera usada.'}
        $exe=$command.Source
    }
    $raw=& $exe status --json 2>$null
    if($LASTEXITCODE){throw 'Nao foi possivel consultar o Tailscale.'}
    $status=($raw -join "`n")|ConvertFrom-Json
    if($status.BackendState -ne 'Running' -or -not $status.Self.Online){throw 'Tailscale precisa estar conectado.'}
    $addresses=@($status.Self.TailscaleIPs | Where-Object {$_ -notmatch ':'})
    if($addresses.Count -ne 1){throw 'Nao foi encontrado um unico IPv4 do Tailscale.'}
    $ip=Assert-PackPrivateIPv4 $addresses[0]
    $assigned=@(Get-NetIPAddress -AddressFamily IPv4 -IPAddress $ip -ErrorAction SilentlyContinue)
    if($assigned.Count -ne 1){throw 'O IP do Tailscale nao esta atribuido a uma interface local.'}
    return $ip
}

function Assert-PackPrivateListener([int]$Port,[string]$Address,[string]$SaveRoot,[int]$OwnerPid=0) {
    $listeners=@(Get-NetTCPConnection -LocalPort $Port -State Listen -ErrorAction SilentlyContinue)
    if(-not $listeners.Count){return $false}
    if($listeners.Count -ne 1 -or $listeners[0].LocalAddress -cne $Address){throw 'Listener inesperado: a porta deve escutar somente no endereco privado selecionado.'}
    $process=Get-CimInstance Win32_Process -Filter ('ProcessId='+$listeners[0].OwningProcess)
    $saveArg='(?:^|\s)-tmlsavedirectory\s+"?'+[regex]::Escape($SaveRoot)+'"?(?:\s|$)'
    if(-not $process -or $process.Name -ne 'dotnet.exe' -or $process.CommandLine -notmatch 'tModLoader\.dll' -or
       $process.CommandLine -notmatch '(?:^|\s)-server(?:\s|$)' -or $process.CommandLine -match '(?:^|\s)-subworld(?:\s|$)' -or
       $process.CommandLine -notmatch $saveArg -or ($OwnerPid -and $process.ProcessId -ne $OwnerPid)) {throw 'A porta pertence a outro processo ou perfil.'}
    return $true
}
Export-ModuleMember -Function Assert-PackPrivateIPv4,Get-PackTailscaleIPv4,Assert-PackPrivateListener
