# throw-loop Specification

## Purpose
The throw state machine: predetermined faces, three timed lock windows, tap-to-lock, re-rolls and force-lock.
## Requirements
### Requirement: Throw state machine
A throw SHALL progress `Draw → Tumble → Lock1 → Reroll → Lock2 → Reroll → Lock3 → ForceLock → Resolved`. On `Resolved` the throw SHALL expose the locked dice (faces and lock order) and the recorded per-window remaining times to downstream consumers (scoring). A die is **done** when it is locked or is a dead slot (a shattered Glass die, dice-materials spec); dead slots can never be locked, so they never hold a throw open.

#### Scenario: Full three-window throw
- **WHEN** a throw runs and at least one die remains unlocked through window 3
- **THEN** the states occur in the order above and `Resolved` reports all 3 window times

#### Scenario: Early resolution when everything is locked
- **WHEN** every tray die is done (locked or dead) during window N (N < 3), the last one by a lock
- **THEN** the throw transitions directly to `Resolved`, crediting the remaining time of window N and the full duration of windows N+1..3

#### Scenario: Early resolution with dead slots
- **GIVEN** one Glass die shattered at the end of window 1 and two live dice are left unlocked
- **WHEN** the player locks both live dice 0.5 s into window 2 (window 2.5 s)
- **THEN** the throw resolves at once with window times [0, 2.0, 2.5]

#### Scenario: Re-roll leaves nothing to lock
- **GIVEN** window N (N < 3) expires and, after the re-roll shatters the unlocked Glass dice, no live unlocked die remains
- **WHEN** the re-roll begins
- **THEN** the throw transitions directly to `Resolved` without running windows N+1..3, and those skipped windows are credited **0 s** remaining (no credit: nothing was locked in them)

### Requirement: Faces are predetermined by the seeded RNG
At the start of the tumble and of every re-roll, the face of every affected die SHALL be drawn from the seeded RNG `dice` stream before any presentation begins. The tumble/re-roll animation is pure presentation and SHALL NOT influence outcomes (architectural law, PRD §6).

#### Scenario: Faces fixed before animation
- **WHEN** a tumble or re-roll begins
- **THEN** all resulting faces are already determined, and skipping or altering the animation yields identical faces

#### Scenario: Headless throw
- **WHEN** a throw runs headless (no scene layer)
- **THEN** the same seed produces the same faces, locks permitting, as an on-screen run

### Requirement: Lock window timing
Each lock window SHALL drain over `lock_window_duration_s`, accumulating `delta` in `_process` so the effective duration is frame-rate independent. When the timer empties, the window ends and unlocked dice proceed to re-roll (or force-lock after window 3).

#### Scenario: Window expires
- **WHEN** a window's accumulated time reaches `lock_window_duration_s`
- **THEN** the window closes and all still-unlocked dice are queued for re-roll (windows 1–2) or force-locked (window 3)

#### Scenario: Frame-rate independence
- **WHEN** the same window runs under 30 fps and 60 fps simulated `delta` sequences
- **THEN** the effective window duration in seconds is equal

### Requirement: Tap-to-lock with forgiveness
During a lock window, a tap SHALL lock the nearest unlocked die whose bounds are within `tap_forgiveness_radius_px` of the tap point. Locks are irreversible for the remainder of the throw. Taps on locked dice or outside the radius do nothing.

#### Scenario: Direct tap
- **WHEN** the player taps on an unlocked die during a window
- **THEN** that die locks immediately and is excluded from future re-rolls

#### Scenario: Near miss snaps
- **WHEN** the player taps within `tap_forgiveness_radius_px` of an unlocked die but not on it
- **THEN** the nearest unlocked die within the radius locks

#### Scenario: Tap cannot unlock
- **WHEN** the player taps a locked die
- **THEN** nothing changes

### Requirement: Re-roll between windows
When a window closes with unlocked dice remaining, those dice SHALL receive new faces from the `dice` stream and tumble again before the next window opens. Locked dice keep their faces.

#### Scenario: Partial lock then re-roll
- **WHEN** window 1 closes with 2 of 6 dice locked
- **THEN** the 4 unlocked dice get new RNG faces and the 2 locked dice are unchanged in window 2

### Requirement: Per-window time recording
For each window, the system SHALL record the remaining time at the moment the window ends (by expiry or by all dice becoming done). The three values are exposed on `Resolved` as the raw input for Heat. Windows skipped because the player locked everything early SHALL be credited at full duration; windows skipped because a re-roll left nothing to lock SHALL be credited 0 s.

#### Scenario: Times reported
- **WHEN** a throw resolves
- **THEN** three non-negative remaining-time values are available, one per window, with windows skipped by an early lock credited at full duration and windows skipped because nothing was left to lock credited 0 s

#### Scenario: No credit when nothing is left to lock
- **GIVEN** a tray of 1 Bone and 5 Glass dice, the Bone die locked in window 1 and the Glass dice left unlocked
- **WHEN** window 1 expires and the five Glass dice shatter
- **THEN** the throw resolves with window times [0, 0, 0] and Heat ×1.0, the same Heat as letting windows 2 and 3 run out

### Requirement: Focus-loss protection
On focus loss during a throw, the game SHALL pause immediately and obscure the tray so the board cannot be studied while paused. On resume, a `resume_countdown_s` countdown runs, then the interrupted window restarts from a full timer with all existing locks retained (PRD §5: generous beats fragile).

#### Scenario: Backgrounded mid-window
- **WHEN** the app loses focus during window 2 with some dice locked
- **THEN** the game pauses with the tray obscured, and on resume after the countdown window 2 restarts at full duration with those locks intact

#### Scenario: Focus loss outside a window
- **WHEN** the app loses focus during tumble or between throws
- **THEN** the game pauses with the tray obscured and resumes at the same point after the countdown

### Requirement: THROW button re-enable timing
The THROW button SHALL remain disabled from the moment a throw begins until the score cascade animation fully completes. It SHALL NOT re-enable at the moment the score is computed.

#### Scenario: Button disabled during cascade
- **WHEN** `ThrowController` emits `resolved`
- **THEN** the THROW button remains disabled while `ScoreCascade` is running and becomes enabled only after `ScoreCascade` emits `finished`

#### Scenario: Button disabled when round is complete
- **WHEN** the cascade completes and `RoundState` is done (round won or lost)
- **THEN** the THROW button remains disabled (the round-won/lost state takes precedence)

### Requirement: Charm hooks fire at throw-loop state transitions
`ThrowController` SHALL accept an optional `CharmInventory` at construction (default `null`). When an inventory is provided, it SHALL dispatch hook calls at the following moments:
- **`on_throw`** — immediately after RNG has determined all faces at throw start, before tumble begins
- **`on_window`** — when a lock window opens (after tumble or re-roll completes), passing the 1-based window index
- **`on_lock`** — when a die is locked (by player tap or force-lock), passing die index, face value, and window index

Hook calls SHALL pass a freshly-built `CharmContext` snapshot. Hook calls SHALL NOT affect die faces, lock state, or window timing — they are fire-and-forget in M1 (no return values are read by the engine).

#### Scenario: on_throw fires once per throw
- **WHEN** a throw starts with a charm in the inventory
- **THEN** `on_throw` is called exactly once, after all faces are determined by RNG

#### Scenario: on_window fires at each window open
- **WHEN** a 3-window throw completes with a charm in the inventory
- **THEN** `on_window` is called three times, with `window_index` 1, 2, and 3 in order

#### Scenario: on_lock fires per die locked
- **WHEN** the player locks 2 dice in window 1 and the remaining 4 are force-locked in window 3
- **THEN** `on_lock` fires 6 times total: 2 during window 1, 4 during window 3

#### Scenario: No inventory — no hooks fired
- **WHEN** `ThrowController` is constructed without a `CharmInventory`
- **THEN** no hook calls are made and throw behaviour is identical to M0

### Requirement: Carved dice emit carve_activated on lock
`ThrowController` SHALL emit `signal carve_activated(die_index: int, carve_type: StringName)` when:
1. A die is locked (by player tap or force-lock), AND
2. The die has a non-empty `carve_type`, AND
3. The die's current face equals its `carved_face`

The signal fires after `die_locked` and before charm hooks.

#### Scenario: Spark die locked on carved face
- **GIVEN** a die with `carved_face = 4`, `carve_type = &"spark"` is drawn and locked showing face 4
- **WHEN** the die is locked
- **THEN** `carve_activated` emits with `carve_type = &"spark"`

#### Scenario: Carved die locked on wrong face
- **GIVEN** a die with `carved_face = 4`, `carve_type = &"spark"` is locked showing face 2
- **WHEN** the die is locked
- **THEN** `carve_activated` does NOT emit

### Requirement: Spark extends current lock window
`ThrowScene` SHALL call `ThrowController.freeze_window(0.5)` when `carve_activated` emits with `carve_type == &"spark"`. `freeze_window(duration)` subtracts `duration` from the window's accumulated time, effectively adding that many seconds to the remaining window time, but never above the full window length: accumulated time is floored at 0, so the remaining time is capped at the window's duration (`lock_window_duration_s`, halved on a boss ante).

#### Scenario: Spark extends window by 0.5 s
- **GIVEN** a lock window with 0.8 s remaining (accumulated = window_s - 0.8)
- **WHEN** `freeze_window(0.5)` is called
- **THEN** the window now has 1.3 s remaining

#### Scenario: Spark early in a window is capped
- **GIVEN** a 2.5 s lock window with 0.2 s elapsed (2.3 s remaining)
- **WHEN** `freeze_window(0.5)` is called
- **THEN** the window has 2.5 s remaining, not 2.8 s

### Requirement: ThrowResult carries carve_types parallel array
`ThrowResult.carve_types: Array[StringName]` SHALL hold the carve_type that activated for each tray die, or `&""` if no carve activated. Length equals the number of drawn dice.

#### Scenario: Activated carves recorded per slot
- **GIVEN** a Gem die (carved_face 5) locked showing 5 and a Spark die (carved_face 4) locked showing 2
- **WHEN** the throw resolves
- **THEN** `carve_types` holds `&"gem"` for the Gem slot and `&""` for the Spark slot and every other slot

### Requirement: Boss round halves lock-window duration
On a boss ante, `ThrowScene` SHALL apply `boss_window_scale` to the lock-window duration before constructing the `ThrowController`. The effective window duration for scoring Heat SHALL match the boss-scaled value.

#### Scenario: Boss ante has shorter windows
- **GIVEN** `lock_window_duration_s = 2.5` and `boss_window_scale = 0.5`
- **WHEN** the player enters ante 3 (a boss ante)
- **THEN** each lock window drains in 1.25 s instead of 2.5 s

#### Scenario: Non-boss ante is unaffected
- **WHEN** the player is on ante 1 or 2
- **THEN** lock windows run at the full `lock_window_duration_s`

### Requirement: Round type label shown in UI
`ThrowScene` SHALL display the current ante's round type name (from `AnteConfig.round_names`) in the ante label.

#### Scenario: Boss label visible
- **WHEN** the player enters ante 3
- **THEN** the ante label reads `"ANTE 3 / 3 — BOSS ROUND"`

### Requirement: Die lock triggers haptic feedback
`ThrowScene` SHALL call `Input.vibrate_handheld(30)` each time a die is locked during a lock window. The call is Android-only; on other platforms it is a no-op and requires no guard.

#### Scenario: Die locked → vibration
- **GIVEN** the game is running on Android
- **WHEN** a die is locked during any lock window
- **THEN** the device vibrates for approximately 30 ms

### Requirement: Screen shake on combo land
When a scored throw contains at least one combo, `ThrowScene` SHALL shake when the combo stamp lands. The shake is a decaying oscillation on the scene root's `position.x` in 6 alternating steps, with amplitude and duration from the combo tier (`FeedbackConfig.shake_px_by_tier` and `shake_s_by_tier`; see the score-cascade spec). The shake is a Tween on the scene root `position`. It resolves back to `Vector2.ZERO`, and a new shake replaces one in progress. It does not conflict with `_apply_layout()` because anchors define the Control rect independently of `position`.

#### Scenario: Combo lands → shake
- **GIVEN** a throw resolves with a Pair or better
- **WHEN** the cascade's combo stamp lands
- **THEN** the scene root shakes by its tier's amplitude, which decays to zero within its tier's duration

#### Scenario: No combo → no shake
- **GIVEN** a throw resolves with all loose dice (no combo)
- **WHEN** the cascade plays
- **THEN** no shake is requested

### Requirement: Audio stub infrastructure
`ThrowScene` SHALL own two `AudioStreamPlayer` children (`_sfx_lock`, `_sfx_combo`) created in `_ready()` with `stream = null`. Play calls SHALL be guarded: `if _sfx_lock.stream: _sfx_lock.play()`. Audio assets are assigned in the `.tscn` by the audio designer; no code changes are needed to activate sound once assets exist.

#### Scenario: No stream assigned → no error
- **GIVEN** `_sfx_lock.stream == null`
- **WHEN** a die is locked
- **THEN** no error is thrown and no audio plays

### Requirement: Lock feedback
Each time a die is locked, `ThrowScene` SHALL:
- punch the die to `lock_punch_scale` (current 1.18) and back over `lock_punch_s` (0.18 s);
- play a small shake of `lock_shake_px` (3 px) over `lock_shake_s` (0.1 s);
- keep the existing haptic.

Lock timing is unchanged.

#### Scenario: Lock punches
- **WHEN** a die is locked during a window
- **THEN** it scales up and settles back, and the table nudges

### Requirement: Timer urgency
During the last `urgency_s` (current 0.8 s) of a lock window, the timer fill SHALL shift toward oxblood in proportion to how little time is left, and pulse. The frame pulses with it. Outside that stretch, and outside windows, both show untinted. Window timing is unchanged.

#### Scenario: Last stretch turns urgent
- **WHEN** less than `urgency_s` remains in a window
- **THEN** the fill is tinted toward red, and returns to untinted when the window ends

