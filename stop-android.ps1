param(
    [string]$EmulatorId = "Pixel_8_API_36_clean"
)

$ErrorActionPreference = "Stop"

$adb = "C:\Users\ROZAN\AppData\Local\Android\Sdk\platform-tools\adb.exe"

if (-not (Test-Path $adb)) {
    throw "adb not found: $adb"
}

try {
    & $adb emu kill
} catch {
    Write-Host "adb emu kill failed. Continuing with process cleanup..."
}

$emulatorProcesses = Get-CimInstance Win32_Process -Filter "name = 'emulator.exe'"
foreach ($process in $emulatorProcesses) {
    if ($process.CommandLine -match "-avd\s+$([regex]::Escape($EmulatorId))(\s|$)") {
        Stop-Process -Id $process.ProcessId -Force
    }
}

$qemuProcesses = Get-CimInstance Win32_Process -Filter "name = 'qemu-system-x86_64.exe'"
foreach ($process in $qemuProcesses) {
    if ($process.CommandLine -match [regex]::Escape($EmulatorId)) {
        Stop-Process -Id $process.ProcessId -Force
    }
}
