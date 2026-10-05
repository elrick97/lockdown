# throw-loop Specification

## Purpose
The throw state machine: predetermined faces, three timed lock windows, tap-to-lock, re-rolls and force-lock.
## Requirements
### Requirement: Throw state machine
A throw SHALL progress `Draw → Tumble → Lock1 → Reroll → Lock2 → Reroll → Lock3 → ForceLock → Resolved`. On `Resolved` the throw SHALL expose the locked dice (faces and lock order) and the recorded per-window remaining times to downstream consumers (scoring).

#### Scenario: Full three-window throw
- **WHEN** a throw runs and at least one die remains unlocked through window 3
- **THEN** the states occur in the order above and `Resolved` reports all 3 window times

#### Scenario: Early resolution when everything is locked
- **WHEN** every tray die is locked during window N (N < 3)
- **THEN** the throw transitions directly to `Resolved`, crediting the full duration of windows N+1..3 as remaining time

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
For each window, the system SHALL record the remaining time at the moment the window ends (by expiry or by all dice becoming locked). The three values are exposed on `Resolved` as the raw input for Heat (computed in a later change, not here).

#### Scenario: Times reported
- **WHEN** a throw resolves
- **THEN** three non-negative remaining-time values are available, one per window, with skipped windows credited at full duration

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

