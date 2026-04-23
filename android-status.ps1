$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$flutter = Join-Path $projectRoot ".tooling\flutter-sdk\bin\flutter.bat"
$adb = "C:\Users\ROZAN\AppData\Local\Android\Sdk\platform-tools\adb.exe"

if (-not (Test-Path $flutter)) {
    throw "Flutter SDK not found: $flutter"
}

if (-not (Test-Path $adb)) {
    throw "adb not found: $adb"
}

Write-Host "`nFlutter devices:`n"
& $flutter devices

Write-Host "`nadb devices:`n"
& $adb devices

Write-Host "`nFlutter emulators:`n"
& $flutter emulators
