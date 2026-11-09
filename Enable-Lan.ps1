# Run once in an Administrator PowerShell while this project's server is running.
#Requires -RunAsAdministrator
param([int]$Port = 8080, [string]$InterfaceAlias = '')
$ErrorActionPreference = 'Stop'
if ($Port -lt 1 -or $Port -gt 65535) { throw 'Port must be in 1..65535.' }
# The Windows TCP table can report a blank State for the listening socket.
$listener = Get-NetTCPConnection -LocalPort $Port -ErrorAction SilentlyContinue |
    Where-Object { $_.LocalAddress -in @('0.0.0.0','127.0.0.1') -and -not $_.RemotePort -and $_.OwningProcess -gt 0 } |
    Sort-Object LocalAddress |
    Select-Object -First 1
if (-not $listener) {
    throw "Chua co server tren cong $Port. Chay .\Run-Server.ps1 -Lan -Port $Port trong terminal du an, doi dong 'Thiet bi cung mang', roi chay lai Enable-Lan.ps1."
}
$serverProcess = Get-CimInstance Win32_Process -Filter "ProcessId = $($listener.OwningProcess)" -ErrorAction SilentlyContinue
$expectedScript = Join-Path $PSScriptRoot 'backend\run_local_server.py'
if (-not $serverProcess.CommandLine -or -not $serverProcess.CommandLine.Contains($expectedScript)) {
    throw 'Run this project with Run-Server.ps1 -Lan first; no firewall rule was added.'
}
if ($listener.LocalAddress -ne '0.0.0.0') {
    throw "Server tren cong $Port chi nghe tren may nay. Nhan Ctrl+C trong terminal server, roi chay lai .\Run-Server.ps1 -Lan -Port $Port."
}
$pythonPath = $serverProcess.ExecutablePath
if (-not $InterfaceAlias) {
    $network = Get-NetConnectionProfile | Where-Object { $_.IPv4Connectivity -eq 'Internet' } | Select-Object -First 1
} else {
    $network = Get-NetConnectionProfile -InterfaceAlias $InterfaceAlias | Select-Object -First 1
}
$profile = [string]$network.NetworkCategory
if ($profile -notin @('Private','Public')) {
    throw 'Choose your trusted LAN interface with -InterfaceAlias.'
}
$ruleName = "WebVinhNam-Server-LAN-$Port-$($network.InterfaceIndex)"
if (Get-NetFirewallRule -Name $ruleName -ErrorAction SilentlyContinue) {
    Write-Host "Rule already exists: $ruleName. Inspect it with Get-NetFirewallRule before changing it."
} else {
    New-NetFirewallRule -Name $ruleName -DisplayName $ruleName -Direction Inbound -Action Allow -Protocol TCP -LocalPort $Port -RemoteAddress LocalSubnet -Profile $profile -InterfaceAlias $network.InterfaceAlias -Program $pythonPath | Out-Null
    Write-Host "Allowed LocalSubnet to port $Port for this server on $($network.InterfaceAlias), profile $profile."
}
