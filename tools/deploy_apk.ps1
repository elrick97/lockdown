# Install and launch the debug APK on a connected Android device.
# Run tools/build_apk.ps1 first.
$projectRoot = Split-Path $PSScriptRoot -Parent
$apk = Join-Path $projectRoot "build\lockdown.apk"
$package = "com.lockdown.proto"

if (-not (Test-Path $apk)) { Write-Error "No APK at build\lockdown.apk - run tools/build_apk.ps1 first"; exit 1 }

$adb = Get-Command adb -ErrorAction SilentlyContinue
if ($adb) { $adb = $adb.Source } else { $adb = Join-Path $env:ANDROID_SDK_ROOT "platform-tools\adb.exe" }
if (-not (Test-Path $adb)) { Write-Error "adb not found on PATH or under ANDROID_SDK_ROOT"; exit 1 }

# Show attached devices. A line ending in 'device' is ready; 'unauthorized'
# means the on-screen USB-debugging prompt hasn't been accepted yet.
$devices = & $adb devices
Write-Host ($devices -join "`n")
$ready = $devices | Select-String -Pattern "\sdevice$"
if (-not $ready) {
    Write-Host ""
    Write-Host "No authorized device found."
    Write-Host "  - Plug in the phone with a data-capable USB cable"
    Write-Host "  - Enable Developer Options then USB debugging"
    Write-Host "  - Accept the 'Allow USB debugging?' prompt on the device, then re-run"
    exit 1
}

Write-Host "Installing $apk ..."
& $adb install -r $apk
if ($LASTEXITCODE -ne 0) { Write-Error "adb install failed (exit $LASTEXITCODE)"; exit $LASTEXITCODE }

Write-Host "Launching $package ..."
& $adb shell monkey -p $package -c android.intent.category.LAUNCHER 1 | Out-Null
Write-Host "Launched. Check the device screen."
exit 0
