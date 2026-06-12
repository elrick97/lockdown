# Spec: throw-loop

Named tunables introduced here (current values): `tumble_duration_s` = **1.5**, `lock_window_duration_s` = **2.5**, `tap_forgiveness_radius_px` = **96** (base-resolution px beyond die bounds), `resume_countdown_s` = **3**.

## ADDED Requirements

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
