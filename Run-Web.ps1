# Keep script text ASCII-compatible with Windows PowerShell 5.1.
param(
    [string]$Flutter = 'D:\flutter\bin\flutter.bat',
    [string]$ApiUrl = 'http://127.0.0.1:8765',
    [ValidateRange(1,65535)][int]$Port = 8081
)
$ErrorActionPreference = 'Stop'
if (-not (Test-Path -LiteralPath $Flutter)) { throw 'Chon Flutter SDK bang tham so -Flutter.' }
# Reserve port 8080 for the LAN demo. Detect a busy development port before pub get.
$portProbe = [System.Net.Sockets.TcpListener]::new([System.Net.IPAddress]::Loopback, $Port)
try {
    $portProbe.ExclusiveAddressUse = $true
    $portProbe.Start()
} catch {
    throw "Khong mo duoc cong $Port. Mo web dang chay, hoac dung .\Run-Web.ps1 -Port 8082. Chi tiet: $($_.Exception.Message)"
} finally {
    $portProbe.Stop()
}
Write-Host "Web phat trien: http://127.0.0.1:$Port/"
Write-Host "Dung API: $ApiUrl. Neu Run-Server dang chay, khong chay them Run-Chat."
$savedFlutterWindows = $env:FLUTTER_WINDOWS
$savedFlutterLinux = $env:FLUTTER_LINUX
$env:FLUTTER_WINDOWS = 'false'
$env:FLUTTER_LINUX = 'false'
Push-Location $PSScriptRoot
try {
    & $Flutter pub get
    if ($LASTEXITCODE -ne 0) { throw 'Khong cai duoc thu vien Flutter.' }
    & $Flutter run --no-pub -d chrome --web-hostname 127.0.0.1 --web-port $Port "--dart-define=MEDGEMMA_API_BASE_URL=$ApiUrl"
    if ($LASTEXITCODE -ne 0) { throw 'Khong khoi dong duoc Flutter Web. Xem thong bao phia tren.' }
} finally {
    Pop-Location
    $env:FLUTTER_WINDOWS = $savedFlutterWindows
    $env:FLUTTER_LINUX = $savedFlutterLinux
}
