param(
    [switch]$WebServer,
    [switch]$NoPubGet,
    [int]$Port = 7363
)

$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$flutter = Join-Path $projectRoot ".tooling\flutter-sdk\bin\flutter.bat"

if (-not (Test-Path $flutter)) {
    throw "Flutter SDK not found: $flutter"
}

Set-Location $projectRoot

if (-not $NoPubGet) {
    Write-Host "Getting packages..."
    & $flutter pub get
}

if ($WebServer) {
    Write-Host "Running app on web-server port $Port..."
    & $flutter run -d web-server --web-port $Port
    return
}

Write-Host "Running app on Chrome..."
& $flutter run -d chrome
