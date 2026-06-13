# Spec: android-export

Named values (current): export preset name = **"Android"**; package id = **`com.lockdown.proto`** (placeholder pending M1 name decision); APK output = **`build/lockdown.apk`**; engine = **4.6.3.stable**.

## ADDED Requirements

### Requirement: Repeatable headless debug build
The project SHALL produce a debug APK from a single command (`tools/build_apk.ps1`) with no editor GUI interaction. The script SHALL import the project before exporting (refreshing the class cache, as the test runner does) and SHALL write the APK to `build/lockdown.apk`.

#### Scenario: One-command build
- **WHEN** `tools/build_apk.ps1` is run with the 4.6.3.stable export templates installed
- **THEN** a debug APK is written to `build/lockdown.apk` and the script reports its path and size

#### Scenario: Templates missing fails clearly
- **WHEN** the build is run with the export templates directory empty
- **THEN** the script stops with a message naming the required version (4.6.3.stable) and the editor install path, rather than producing a broken or partial APK

### Requirement: Portrait mobile export preset
The Android export preset SHALL target portrait orientation and the gl_compatibility mobile renderer, matching the project's display settings, and SHALL identify the app with the placeholder package id `com.lockdown.proto`.

#### Scenario: Preset matches project display config
- **WHEN** the APK is built and installed
- **THEN** the app launches locked to portrait at the device resolution, consistent with `window/handheld/orientation=1`

### Requirement: No secrets in version control
The debug APK SHALL be signed using the debug keystore configured in Godot editor settings, not a keystore committed to the repo. `export_presets.cfg` SHALL be committed (for reproducible builds) but SHALL contain no keystore passwords or release credentials. `*.keystore` / `*.jks` SHALL remain git-ignored.

#### Scenario: Preset is committed without credentials
- **WHEN** `export_presets.cfg` is inspected in version control
- **THEN** it contains the debug export configuration and placeholder package id but no keystore path with an embedded release password

#### Scenario: Keystores stay ignored
- **WHEN** a `.keystore` or `.jks` file exists in the working tree
- **THEN** git ignores it (release signing remains a manual, out-of-repo step)

### Requirement: APK output is not committed
The `build/` directory holding generated APKs SHALL be git-ignored so binaries never enter the repo.

#### Scenario: Built APK is ignored
- **WHEN** `tools/build_apk.ps1` writes `build/lockdown.apk`
- **THEN** git does not track the APK

### Requirement: On-device playable verification
The exported APK SHALL run the full playable throw loop on a real mid-range Android device: draw, tumble, tap-to-lock across the three windows, scoring, and the round/ante win-lose flow, with touch input driving the locks.

#### Scenario: Full loop on device
- **WHEN** the APK is deployed to a mid-range device and launched
- **THEN** a player can throw, lock dice by tapping, see the score breakdown, and reach a round win or loss using touch alone
