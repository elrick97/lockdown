## ADDED Requirements

### Requirement: Die lock triggers haptic feedback
`ThrowScene` SHALL call `Input.vibrate_handheld(30)` each time a die is locked during a lock window. The call is Android-only; on other platforms it is a no-op and requires no guard.

#### Scenario: Die locked → vibration
- **GIVEN** the game is running on Android
- **WHEN** a die is locked during any lock window
- **THEN** the device vibrates for approximately 30 ms

### Requirement: Screen shake on combo land
When a throw resolves and the scoring breakdown contains at least one combo, `ThrowScene` SHALL play a brief screen-shake: a decaying oscillation on the scene root's `position.x` property, amplitude **8 px**, duration **0.25 s**, 6 alternating steps (named tunables: `shake_amplitude_px = 8`, `shake_duration_s = 0.25`, `shake_steps = 6`). The shake is implemented as a Tween on the scene root `position` and resolves back to `Vector2.ZERO`. It does not conflict with `_apply_layout()` because anchors define the Control rect independently of `position`.

#### Scenario: Combo lands → shake
- **GIVEN** a throw resolves with a Pair or better
- **WHEN** `ScoreCascade.play()` begins
- **THEN** the scene root shakes briefly (amplitude decays to zero within `shake_duration_s`)

#### Scenario: No combo → no shake
- **GIVEN** a throw resolves with all loose dice (no combo)
- **WHEN** `ScoreCascade.play()` begins
- **THEN** no position tween is started

### Requirement: Audio stub infrastructure
`ThrowScene` SHALL own two `AudioStreamPlayer` children (`_sfx_lock`, `_sfx_combo`) created in `_ready()` with `stream = null`. Play calls SHALL be guarded: `if _sfx_lock.stream: _sfx_lock.play()`. Audio assets are assigned in the `.tscn` by the audio designer; no code changes are needed to activate sound once assets exist.

#### Scenario: No stream assigned → no error
- **GIVEN** `_sfx_lock.stream == null`
- **WHEN** a die is locked
- **THEN** no error is thrown and no audio plays
