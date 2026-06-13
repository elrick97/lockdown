# Tasks: add-android-export

## 1. Prerequisite (manual, user)

- [x] 1.1 Install 4.6.3.stable export templates via Godot: Editor → Manage Export Templates → Download and Install; then verify `%APPDATA%\Godot\export_templates\4.6.3.stable\` is populated (build script checks this) ✓ android_debug.apk present (124 MB)

## 2. Export preset

- [x] 2.1 Create `export_presets.cfg` with an "Android" preset (GUI-regenerated, valid; arm64-v8a only, package id `com.lockdown.proto`, export path `build/lockdown.apk`, debug signing via editor settings — no secrets in file); `exclude_filter="tests/*,addons/gut/*"` keeps test/editor code out of the APK
- [x] 2.1a RESOLVED: root cause was a missing project setting, not the preset. Mobile GL export requires `rendering/textures/vram_compression/import_etc2_astc=true`; this `can_export` check fails first and the headless CLI suppresses its message, masquerading as a generic "configuration error". Added the setting to `project.godot`.
- [x] 2.2 Add a header comment to `export_presets.cfg`: debug-only, no release secrets in this file (release signing is manual)

## 3. .gitignore

- [x] 3.1 Remove `export_presets.cfg` from `.gitignore`; keep `*.keystore` / `*.jks` ignored; add `build/` so generated APKs are not tracked

## 4. Build + deploy scripts

- [x] 4.1 `tools/build_apk.ps1`: locate `godot_console.exe` (PATH or `C:\Tools\Godot`); fail clearly if templates dir is empty; run `--headless --path <root> --import`; then `--headless --path <root> --export-debug "Android" build/lockdown.apk`; report APK path + size; exit non-zero on failure
- [x] 4.2 `tools/deploy_apk.ps1`: show `adb devices`; if a device is authorized, `adb install -r build/lockdown.apk` then launch via `adb shell monkey -p com.lockdown.proto 1` (or `am start`); print clear guidance if no/unauthorized device

## 5. Build verification (headless)

- [x] 5.1 Run `tools/build_apk.ps1`; confirm `build/lockdown.apk` is produced and non-trivial in size (>5 MB sanity floor) ✓ 26.3 MB, signed + verified, clean (no script errors after test/gut exclusion)

## 6. On-device verification (manual, user)

- [x] 6.1 Plug in a mid-range Android phone with USB debugging enabled; run `tools/deploy_apk.ps1`; accept the device authorization prompt if shown ✓ installed + launched on Pixel 9 (tokay); process alive, logcat clean (no crash/FATAL/resource errors)
- [x] 6.2a BLOCKER FOUND + FIXED: UI collapsed top-left on Android (fine on desktop). Root cause: Android export strips Control anchor/offset metadata from the hand-authored .tscn. Fix: drive the throw-scene layout in code (`_apply_layout`), stretch mode `viewport`/`keep`. Verified on device: full ante/throw/total HUD, dice grid, lock coloring, and timer bar all render correctly; touch-driven throw + lock confirmed via adb. (design decision #8)
- [x] 6.2 On-device play verified: full ante/throw/total HUD, dice grid, lock coloring, timer bar render correctly; touch-driven throw + lock confirmed. (Subjective lock-feel/timer-tension tuning belongs to the M0 prototype-playtest tasks, not this plumbing change.)
- [x] 6.3 Window-override letterbox risk (design risk #1) ruled out — overrides never affected Android (they are desktop-only); restored as `.windows`-tagged for desktop fit. Minor top/bottom letterbox bars come from `viewport`/`keep` stretch on the 2400-vs-2424 height delta (acceptable for gray-box)

## 7. Wrap up

- [x] 7.1 Update `TASKS.md`: tick "Android export pipeline working" with `add-android-export`
- [x] 7.2 Commit (`export_presets.cfg`, scripts, `.gitignore`; NOT the APK)
