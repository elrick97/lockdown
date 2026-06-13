## Why

M0's kill-gate is a fun-finding playtest, and the prototype is now playable end-to-end. But the lock-window mechanic is a *touch* mechanic under *time pressure* — its real feel (thumb reach, tap forgiveness, the adrenaline of a draining timer) cannot be judged with a mouse on a desktop monitor. The throw loop must be in a thumb on a real phone before the playtest produces trustworthy signal. This also unblocks the dice-visual spike, whose decision criterion is mid-range Android perf.

**Design pillars served:** One thumb, one screen (the entire premise is unverifiable off-device); Flow under pressure (timer tension reads differently on a held device than a desktop window).

## What Changes

- Add an **Android debug export preset** (`export_presets.cfg`) targeting portrait, gl_compatibility/mobile, using the already-configured editor-settings debug keystore.
- Add a **repeatable headless build script** (`tools/build_apk.ps1`) so an APK is one command, not a GUI dance — keeps the future CI balance-sim/build path open.
- Add a **deploy helper** (`tools/deploy_apk.ps1`) wrapping `adb install` + launch.
- **Un-ignore `export_presets.cfg`** in `.gitignore` so the build is reproducible (debug-only; the "release signing is manual" rule keeps secrets out of it).
- Document the one manual prerequisite: installing the 4.6.3.stable export templates via the Godot editor (chosen over scripted download for version-safety).

## Capabilities

### New Capabilities
- `android-export`: the project can produce a deployable debug APK from a repeatable command and run the playable throw loop on a real Android device.

### Modified Capabilities
*(none — no game behavior changes; this is build/deploy plumbing)*

## Impact

- New: `export_presets.cfg`, `tools/build_apk.ps1`, `tools/deploy_apk.ps1`
- Modified: `.gitignore` (un-ignore `export_presets.cfg`; add `build/` for APK output)
- No changes to any gameplay script, scene, resource, or test
- External prerequisites (already satisfied on this machine): Android SDK, JDK, debug keystore, adb — all detected and configured in Godot editor settings
- Manual prerequisite: 4.6.3.stable export templates installed via editor GUI; a mid-range device with USB debugging for the verification step

## Non-goals

- Release/signed builds, Play Store upload, app-store metadata (M4)
- Gradle custom build template / Android plugins (not needed for a prebuilt-template debug APK; revisit if min-SDK control or plugins are required)
- iOS export (M3)
- CI automation of the build (the script makes it *possible*; wiring CI is later)
- Finalizing the application id / app name (M1 name decision — a placeholder id is used)
