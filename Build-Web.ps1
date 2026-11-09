# ASCII-compatible with Windows PowerShell 5.1.
param([string]$Flutter = 'D:\flutter\bin\flutter.bat')
$ErrorActionPreference = 'Stop'
if (-not (Test-Path -LiteralPath $Flutter)) { throw 'Chon Flutter SDK bang -Flutter.' }
$savedWindows = $env:FLUTTER_WINDOWS
$savedLinux = $env:FLUTTER_LINUX
$env:FLUTTER_WINDOWS = 'false'
$env:FLUTTER_LINUX = 'false'
Push-Location $PSScriptRoot
try {
    & $Flutter pub get
    if ($LASTEXITCODE -ne 0) { throw 'Khong tai duoc thu vien Flutter.' }
    # Relative API URLs work on both localhost and another machine's LAN address.
    & $Flutter build web --no-web-resources-cdn --dart-define=MEDGEMMA_API_BASE_URL=/
    if ($LASTEXITCODE -ne 0) { throw 'Build web that bai.' }
} finally {
    Pop-Location
    $env:FLUTTER_WINDOWS = $savedWindows
    $env:FLUTTER_LINUX = $savedLinux
}
