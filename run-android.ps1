param(
    [switch]$Clean,
    [switch]$NoLaunch,
    [string]$EmulatorId = "Pixel_8_API_36",
    [string]$DeviceId = "emulator-5554"
)

$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$flutter = Join-Path $projectRoot ".tooling\flutter-sdk\bin\flutter.bat"
$adb = "C:\Users\ROZAN\AppData\Local\Android\Sdk\platform-tools\adb.exe"

function Require-CommandPath {
    param(
        [string]$Path,
        [string]$Label
    )

    if (-not (Test-Path $Path)) {
        throw "$Label not found: $Path"
    }
}

function Get-AdbState {
    param([string]$TargetDevice)

    $lines = & $adb devices
    foreach ($line in $lines) {
        if ($line -match "^\Q$TargetDevice\E\s+(\S+)$") {
            return $Matches[1]
        }
    }
    return $null
}

function Wait-ForDeviceReady {
    param(
        [string]$TargetDevice,
        [int]$TimeoutSeconds = 240
    )

    $deadline = (Get-Date).AddSeconds($TimeoutSeconds)
    while ((Get-Date) -lt $deadline) {
        $state = Get-AdbState -TargetDevice $TargetDevice
        if ($state -eq "device") {
            return
        }
        Start-Sleep -Seconds 3
    }

    throw "Timed out waiting for $TargetDevice to become ready."
}

Require-CommandPath -Path $flutter -Label "Flutter SDK"
Require-CommandPath -Path $adb -Label "adb"

Set-Location $projectRoot

if (-not $NoLaunch) {
    Write-Host "Launching emulator: $EmulatorId"
    & $flutter emulators --launch $EmulatorId
    Write-Host "Waiting for $DeviceId..."
    Wait-ForDeviceReady -TargetDevice $DeviceId
}

if ($Clean) {
    Write-Host "Cleaning project..."
    & $flutter clean
}

Write-Host "Getting packages..."
& $flutter pub get

Write-Host "Running app on $DeviceId..."
& $flutter run -d $DeviceId
