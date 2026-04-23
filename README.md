# Smart Insole Gait Analysis App

Flutter app skeleton for real-time smart insole gait analysis.

## Current state

- `lib/` structure implemented from product spec
- Riverpod providers wired for WebSocket, calibration, session recording, and local cache
- UI screens included for Home, Calibration, Dashboard, and Session
- Android emulator workflow is configured
- Demo WebSocket stream auto-runs until the real AWS endpoint replaces the placeholder

## Quick start

Run these commands from the project root:

```powershell
cd C:\Users\ROZAN\source\repos\CAPSTONE
.\run-all.ps1
```

That launches the Android emulator and runs the app.

## Shortcut scripts

All scripts live in the project root.

### Main dispatcher

```powershell
.\run-all.ps1
```

Targets:

- Android emulator:
  ```powershell
  .\run-all.ps1
  ```
- Web in Chrome:
  ```powershell
  .\run-all.ps1 -Target web
  ```
- Web server:
  ```powershell
  .\run-all.ps1 -Target web-server
  ```
- Environment checks:
  ```powershell
  .\run-all.ps1 -Target doctor
  ```
- Device and emulator status:
  ```powershell
  .\run-all.ps1 -Target status
  ```
- Stop Android emulator:
  ```powershell
  .\run-all.ps1 -Target stop-android
  ```

### Direct scripts

- Android:
  ```powershell
  .\run-android.ps1
  ```
- Web:
  ```powershell
  .\run-web.ps1
  ```
- Doctor:
  ```powershell
  .\doctor.ps1
  ```

## Android notes

- Emulator id: `Pixel_8_API_36_clean`
- Device id after boot: `emulator-5554`
- Default GPU mode: `swiftshader_indirect`
- If the emulator is already open:
  ```powershell
  .\run-android.ps1 -NoLaunch
  ```
- If you want a clean rebuild:
  ```powershell
  .\run-android.ps1 -Clean
  ```
- If you want to override the emulator or GPU mode:
  ```powershell
  .\run-android.ps1 -EmulatorId Pixel_8_API_36_clean -GpuMode swiftshader_indirect
  ```

## Web notes

- Chrome mode:
  ```powershell
  .\run-web.ps1
  ```
- Web server mode:
  ```powershell
  .\run-web.ps1 -WebServer
  ```
- Custom web server port:
  ```powershell
  .\run-web.ps1 -WebServer -Port 8080
  ```

## Health checks

Static checks:

```powershell
.\doctor.ps1
```

Project verification:

```powershell
C:\Users\ROZAN\source\repos\CAPSTONE\.tooling\flutter-sdk\bin\flutter.bat analyze
C:\Users\ROZAN\source\repos\CAPSTONE\.tooling\flutter-sdk\bin\flutter.bat test
```

## WebSocket endpoint

Replace the placeholder endpoint in `lib/services/websocket_service.dart` when the AWS WebSocket backend is ready.
