param(
    [ValidateSet("android", "web", "web-server", "doctor", "status", "stop-android")]
    [string]$Target = "android",
    [switch]$Clean,
    [switch]$NoLaunch,
    [switch]$NoPubGet,
    [int]$Port = 7363
)

$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path

switch ($Target) {
    "android" {
        & (Join-Path $projectRoot "run-android.ps1") -Clean:$Clean -NoLaunch:$NoLaunch
    }
    "web" {
        & (Join-Path $projectRoot "run-web.ps1") -NoPubGet:$NoPubGet
    }
    "web-server" {
        & (Join-Path $projectRoot "run-web.ps1") -WebServer -NoPubGet:$NoPubGet -Port $Port
    }
    "doctor" {
        & (Join-Path $projectRoot "doctor.ps1")
    }
    "status" {
        & (Join-Path $projectRoot "android-status.ps1")
    }
    "stop-android" {
        & (Join-Path $projectRoot "stop-android.ps1")
    }
}
