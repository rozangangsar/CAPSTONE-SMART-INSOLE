$ErrorActionPreference = "Stop"

$adb = "C:\Users\ROZAN\AppData\Local\Android\Sdk\platform-tools\adb.exe"

if (-not (Test-Path $adb)) {
    throw "adb not found: $adb"
}

& $adb emu kill
