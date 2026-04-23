param(
    [switch]$Clean,
    [switch]$NoLaunch,
    [switch]$NoPubGet,
    [switch]$ColdBoot,
    [string]$EmulatorId = "Pixel_8_API_36_clean",
    [string]$DeviceId = "emulator-5554",
    [ValidateSet("swiftshader_indirect", "auto", "host", "angle")]
    [string]$GpuMode = "swiftshader_indirect",
    [int]$BootTimeoutSeconds = 360
)

$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$flutter = Join-Path $projectRoot ".tooling\flutter-sdk\bin\flutter.bat"
$emulator = "C:\Users\ROZAN\AppData\Local\Android\Sdk\emulator\emulator.exe"
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
    $escapedTargetDevice = [regex]::Escape($TargetDevice)
    foreach ($line in $lines) {
        if ($line -match "^$escapedTargetDevice\s+(\S+)$") {
            return $Matches[1]
        }
    }
    return $null
}

function Restart-AdbServer {
    Write-Host "Restarting adb server..."
    & $adb kill-server | Out-Null
    & $adb start-server | Out-Null
}

function Stop-StaleFlutterProcesses {
    param([string]$ProjectPath)

    $normalizedProjectPath = $ProjectPath.ToLowerInvariant()
    $candidateProcesses = Get-CimInstance Win32_Process | Where-Object {
        $_.Name -in @("dart.exe", "flutter.bat", "cmd.exe", "powershell.exe", "pwsh.exe")
    }

    foreach ($process in $candidateProcesses) {
        $commandLine = "$($process.CommandLine)".ToLowerInvariant()
        if (-not $commandLine) {
            continue
        }

        $looksLikeFlutterRun = $commandLine.Contains($normalizedProjectPath) -and (
            $commandLine.Contains("flutter_tools.snapshot") -or
            $commandLine.Contains("flutter.bat") -or
            $commandLine.Contains(" run ")
        )

        if ($looksLikeFlutterRun -and $process.ProcessId -ne $PID) {
            Write-Host "Stopping stale Flutter process $($process.ProcessId)..."
            Stop-Process -Id $process.ProcessId -Force -ErrorAction SilentlyContinue
        }
    }
}

function Test-EmulatorProcessRunning {
    param([string]$AvdName)

    $emulatorProcesses = Get-CimInstance Win32_Process -Filter "name = 'emulator.exe'"
    foreach ($process in $emulatorProcesses) {
        if ($process.CommandLine -match "-avd\s+$([regex]::Escape($AvdName))(\s|$)") {
            return $true
        }
    }

    return $false
}

function Stop-EmulatorProcess {
    param([string]$AvdName)

    $emulatorProcesses = Get-CimInstance Win32_Process -Filter "name = 'emulator.exe'"
    foreach ($process in $emulatorProcesses) {
        if ($process.CommandLine -match "-avd\s+$([regex]::Escape($AvdName))(\s|$)") {
            Write-Host "Stopping stale emulator process for $AvdName..."
            Stop-Process -Id $process.ProcessId -Force
        }
    }

    $qemuProcesses = Get-CimInstance Win32_Process -Filter "name = 'qemu-system-x86_64.exe'"
    foreach ($process in $qemuProcesses) {
        if ($process.CommandLine -match [regex]::Escape($AvdName)) {
            Stop-Process -Id $process.ProcessId -Force
        }
    }
}

function Wait-ForDeviceReady {
    param(
        [string]$TargetDevice,
        [int]$TimeoutSeconds = 240
    )

    $deadline = (Get-Date).AddSeconds($TimeoutSeconds)
    while ((Get-Date) -lt $deadline) {
        $state = Get-AdbState -TargetDevice $TargetDevice
        if ($state -eq "offline") {
            Write-Host "Device is offline. Requesting adb reconnect..."
            & $adb reconnect | Out-Null
            Start-Sleep -Seconds 5
            continue
        }
        if ($state -eq "device") {
            return
        }
        Start-Sleep -Seconds 3
    }

    throw "Timed out waiting for $TargetDevice to become ready."
}

function Wait-ForBootCompleted {
    param(
        [string]$TargetDevice,
        [int]$TimeoutSeconds = 240
    )

    $deadline = (Get-Date).AddSeconds($TimeoutSeconds)
    while ((Get-Date) -lt $deadline) {
        $bootStatus = (& $adb -s $TargetDevice shell getprop sys.boot_completed 2>$null).Trim()
        if ($LASTEXITCODE -eq 0 -and $bootStatus -eq "1") {
            return
        }
        Start-Sleep -Seconds 5
    }

    throw "Timed out waiting for Android boot to complete on $TargetDevice."
}

function Ensure-DeviceReady {
    param(
        [string]$TargetDevice,
        [int]$TimeoutSeconds
    )

    Write-Host "Waiting for $TargetDevice to appear in adb..."
    Wait-ForDeviceReady -TargetDevice $TargetDevice -TimeoutSeconds $TimeoutSeconds
    Write-Host "Waiting for Android boot to finish..."
    Wait-ForBootCompleted -TargetDevice $TargetDevice -TimeoutSeconds $TimeoutSeconds

    # Wake and unlock emulator so install/start is less flaky after cold boot.
    & $adb -s $TargetDevice shell input keyevent KEYCODE_WAKEUP 2>$null | Out-Null
    & $adb -s $TargetDevice shell wm dismiss-keyguard 2>$null | Out-Null
}

function Start-EmulatorIfNeeded {
    param(
        [string]$AvdName,
        [string]$TargetDevice,
        [switch]$ForceColdBoot,
        [string]$PreferredGpuMode,
        [int]$TimeoutSeconds
    )

    $deviceState = Get-AdbState -TargetDevice $TargetDevice
    if ($deviceState -eq "device") {
        Write-Host "Android device already connected: $TargetDevice"
        Ensure-DeviceReady -TargetDevice $TargetDevice -TimeoutSeconds $TimeoutSeconds
        return
    }

    $emulatorAlreadyRunning = Test-EmulatorProcessRunning -AvdName $AvdName
    if ($emulatorAlreadyRunning) {
        Write-Host "Emulator process found, but $TargetDevice not connected in adb."
        Stop-EmulatorProcess -AvdName $AvdName
        Start-Sleep -Seconds 5
    }

    $launchArgs = @("-avd", $AvdName, "-gpu", $PreferredGpuMode, "-no-boot-anim")
    if ($ForceColdBoot) {
        $launchArgs += "-no-snapshot-load"
    }

    Write-Host "Launching emulator: $AvdName"
    Start-Process -FilePath $emulator -ArgumentList $launchArgs | Out-Null

    Ensure-DeviceReady -TargetDevice $TargetDevice -TimeoutSeconds $TimeoutSeconds
}

function Invoke-FlutterRun {
    param([string]$TargetDevice)

    Write-Host "Running app on $TargetDevice..."
    & $flutter run -d $TargetDevice
    return $LASTEXITCODE
}

Require-CommandPath -Path $flutter -Label "Flutter SDK"
Require-CommandPath -Path $emulator -Label "Android emulator"
Require-CommandPath -Path $adb -Label "adb"

Set-Location $projectRoot

Stop-StaleFlutterProcesses -ProjectPath $projectRoot
Restart-AdbServer

if (-not $NoLaunch) {
    Start-EmulatorIfNeeded -AvdName $EmulatorId -TargetDevice $DeviceId -ForceColdBoot:$ColdBoot -PreferredGpuMode $GpuMode -TimeoutSeconds $BootTimeoutSeconds
} else {
    Ensure-DeviceReady -TargetDevice $DeviceId -TimeoutSeconds $BootTimeoutSeconds
}

if ($Clean) {
    Write-Host "Cleaning project..."
    & $flutter clean
}

if (-not $NoPubGet) {
    Write-Host "Getting packages..."
    & $flutter pub get
}

$runExitCode = Invoke-FlutterRun -TargetDevice $DeviceId
if ($runExitCode -ne 0) {
    $stateAfterFailure = Get-AdbState -TargetDevice $DeviceId
    if ($stateAfterFailure -ne "device") {
        Write-Host "Device disconnected during flutter run. Restarting adb and retrying once..."
        Restart-AdbServer
        Start-EmulatorIfNeeded -AvdName $EmulatorId -TargetDevice $DeviceId -ForceColdBoot:$true -PreferredGpuMode $GpuMode -TimeoutSeconds $BootTimeoutSeconds
        $runExitCode = Invoke-FlutterRun -TargetDevice $DeviceId
    }
}

exit $runExitCode
