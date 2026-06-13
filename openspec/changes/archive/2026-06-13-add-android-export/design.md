## Context

The throw loop is playable but only verifiable on desktop with a mouse — inadequate for a one-thumb, time-pressured touch mechanic. The host machine already has (detected): Android SDK at `%LOCALAPPDATA%\Android\Sdk` (build-tools 35, platforms 34–36, cmdline-tools, platform-tools/adb), a JDK (Android Studio JBR, `JAVA_HOME` set), and a debug keystore at `%APPDATA%\Godot\keystores\debug.keystore` (pass `android`) — all already wired into Godot's `editor_settings-4.6.tres` (`android_sdk_path`, `java_sdk_path`, `debug_keystore`). The single missing piece is the 4.6.3.stable export templates (templates dir exists but is empty).

## Goals / Non-Goals

**Goals:**
- One-command headless debug APK build, mirroring `tools/run_tests.ps1` (import first, then act).
- An `export_presets.cfg` that targets portrait + gl_compatibility mobile and signs with the editor-settings debug keystore (no secrets in the file).
- A deploy helper that installs and launches on a connected device.
- The playable throw loop verified by hand on a real mid-range phone.

**Non-Goals:**
- Release signing, store upload, gradle custom builds, plugins, iOS, CI wiring (see proposal Non-goals).

## Decisions

### 1. Prebuilt export template, not gradle custom build
**Decision:** `gradle_build/use_gradle_build = false`; export with Godot's prebuilt Android template.

**Why:** A prebuilt-template debug APK needs nothing beyond the export templates the user is installing. The gradle path additionally requires installing the Android build template into `res://android/build` and a working gradle toolchain — overhead with no M0 payoff. Gradle is only needed for Android plugins or custom min-SDK/manifest control, neither of which M0 has.

**Alternative considered:** Gradle build now. Rejected as premature; flagged for revisit when the first Android plugin or min-SDK requirement appears.

### 2. Templates installed via editor GUI, not scripted download
**Decision:** The user installs 4.6.3.stable templates through Editor → Manage Export Templates → Download and Install. Documented as a prerequisite; the build script *detects* their absence and fails with a clear message rather than attempting a download.

**Why:** The GUI install auto-matches the exact engine version and hash-verifies. A scripted ~1GB download risks version drift and is a large external fetch. User chose this explicitly.

### 3. Debug signing via editor settings, no secrets in the preset
**Decision:** Leave the preset's keystore fields empty so Godot falls back to the editor-settings debug keystore. Release signing stays manual (per CLAUDE.md).

**Why:** Keeps `export_presets.cfg` free of credentials, which is what makes decision #4 safe.

### 4. Commit `export_presets.cfg` (reverse the current .gitignore exclusion)
**Decision:** Remove `export_presets.cfg` from `.gitignore`; keep `*.keystore`/`*.jks` ignored; add `build/` for APK output.

**Why:** The preset is project configuration — committing it makes builds reproducible and is a prerequisite for any future CI build. It is safe *because* of decision #3: the file carries only debug config and a placeholder package id, never a release secret. This reverses a deliberate prior choice, so it is called out for explicit review.

**Trade-off:** If anyone later adds release keystore details directly into the preset, they'd be committed. Mitigation: the "release signing is manual" rule and a comment in the file forbid release secrets in the preset.

### 5. Placeholder application id
**Decision:** `com.lockdown.proto` as the package `unique_name`, noted as placeholder pending the M1 name decision.

**Why:** A debug-only prototype that never touches a store doesn't need the final id; coupling it to the unresolved name would block the build. Changeable in one line later.

### 6. ETC2/ASTC compression is mandatory for mobile GL export
**Decision:** Set `rendering/textures/vram_compression/import_etc2_astc=true` in `project.godot`.

**Why:** Godot's Android `can_export` hard-requires ETC2/ASTC VRAM compression for the gl_compatibility mobile target. Without it, export fails at validation. Critically, the headless CLI prints this as a *generic* "configuration errors" header with the detail line suppressed — the real message ("Target platform requires 'ETC2/ASTC' texture compression") only appears in the editor's export dialog. Lesson for future build debugging: when headless export fails with a blank config error, open the GUI export dialog to read the actual cause.

### 7. Exclude tests and the GUT addon from the APK
**Decision:** `exclude_filter="tests/*,addons/gut/*"` in the preset.

**Why:** With `export_filter="all_resources"`, GUT's editor/tool scripts were swept into the APK and emitted `Cannot set object script` during export (non-fatal but noisy), and shipping test code in a prototype build is wrong regardless. Excluding them removed the error and trimmed the APK (~27.8 → 26.3 MB).

### 8. Drive the throw-scene layout in code (Android export strips anchors)
**Decision:** `throw_scene.gd` sets every Control's anchors/offsets at runtime in `_apply_layout()` rather than relying on the `.tscn`. Stretch mode is `viewport` / `keep`.

**Why:** On-device testing surfaced a hard blocker: the gray-box UI rendered correctly on desktop but collapsed into the top-left corner on Android. Root cause (confirmed by logging `anchor_*`/`offset_*` on both platforms): the hand-authored `.tscn` omits the `layout_mode`/`anchors_preset` metadata the editor normally writes, and while a desktop source-load tolerates this, the **Android export step resets every Control's layout properties to defaults** (anchors and offsets alike). Adding `layout_mode` by hand did not fix it; a headless `ResourceSaver` re-save corrupted the scene (dropped the script). Setting the layout in code is platform-independent and guaranteed to apply post-load, so it sidesteps the export-serialization defect entirely.

**Trade-off:** The layout now lives in code, duplicating intent that ideally sits in the scene. Tracked as tech-debt: once the scene is re-saved through the Godot editor (which writes correct metadata), the code layout can be removed and verified against a fresh export. Also discovered: mobile GL export requires ETC2/ASTC (decision #6); a blank headless "configuration error" means reading the GUI export dialog.

**Lesson for future scenes:** author `.tscn` files through the editor (or include `layout_mode`/`anchors_preset`), and always verify UI on an exported build, not just desktop.

## Risks / Trade-offs

- **[Desktop window override on mobile]** `project.godot` carries `window_width_override=450` / `height_override=1000` added for desktop fit. On Android the app runs fullscreen at device resolution (canvas_items stretch), so these *should* be ignored — but this must be eyeballed on-device. → If the APK letterboxes to 450×1000, guard the overrides behind a desktop-only feature tag.
- **[Templates absent at build time]** If the user hasn't finished the GUI install, export fails. → The build script checks the templates dir up front and prints the exact install path and steps.
- **[Device not authorized]** `adb devices` may show `unauthorized` until the on-screen USB-debugging prompt is accepted. → Deploy helper surfaces `adb devices` state and the fix.
- **[build-tools/platform mismatch]** Godot 4.6 expects specific build-tools; 35.0.0 is present and compatible. → If export complains, pin the SDK build-tools version in editor settings.
