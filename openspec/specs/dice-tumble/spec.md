# dice-tumble Specification

## Purpose
The invariants every tumble presentation must honor: faces fixed before motion, time-based settling, and gameplay unaffected by the renderer.

The tumble is the presentation of the throw-loop Tumble/Reroll phases. This capability captures only the invariants both spike renderers must honor; the winning renderer's implementation details are intentionally out of scope (a spike yields a decision, not a behavior contract). Tunable: `tumble_duration_s` (current default on `ThrowConfig`).
## Requirements
### Requirement: Tumble animates to predetermined faces
The tumble SHALL animate each unlocked die from a scrambled/in-motion state to its predetermined face, where the face was already drawn from the seeded RNG before the tumble began. The animation SHALL NOT read, consume, or influence the RNG, and SHALL NOT determine or alter any face.

#### Scenario: Faces fixed before motion
- **WHEN** a tumble begins for a set of unlocked dice
- **THEN** each die's final face equals the face `RngService` already assigned, and altering or skipping the animation produces the same faces

#### Scenario: No RNG consumption during presentation
- **WHEN** the tumble animation runs (any renderer)
- **THEN** no additional draws are taken from any RNG stream, so the run remains reproducible from its seed

### Requirement: Tumble settles within the tumble duration
The tumble SHALL reach its settled state (all animating dice showing their final faces) within `tumble_duration_s`, after which the throw proceeds to the lock window. Settling SHALL be frame-rate independent (driven by accumulated `delta`, consistent with the throw-loop timers).

#### Scenario: Settles before the window opens
- **WHEN** `tumble_duration_s` has elapsed since the tumble began
- **THEN** every animating die shows its final face and the first lock window can open

#### Scenario: Same settle time across frame rates
- **WHEN** the same tumble runs under different frame rates
- **THEN** the wall-clock settle time is equivalent (the animation is time-based, not frame-counted)

### Requirement: Locked dice do not tumble
Dice locked in a previous window SHALL retain their faces and SHALL NOT animate during a re-roll tumble; only unlocked dice tumble to new predetermined faces.

#### Scenario: Re-roll tumbles only unlocked dice
- **WHEN** a re-roll tumble begins with some dice locked
- **THEN** the locked dice are visually static on their existing faces and only the unlocked dice animate

### Requirement: Dice land on their face by orientation
Each die SHALL be a single six-face mesh (standard layout, art-direction spec). The tumble SHALL end with each die oriented so its predetermined face points up, turned about the vertical axis by a yaw derived from the die's slot index alone. The start orientation and spin SHALL also derive from the slot index. Presentation SHALL NOT read the RNG; faces stay fixed before motion (existing requirements unchanged).

#### Scenario: Every face lands up
- **WHEN** a die settles on face v (1–6) in any slot
- **THEN** the mesh's face-v normal points straight up (within 1°), and the face's pips read upright to the tilted camera

#### Scenario: Same throw, same picture
- **WHEN** the same faces are tumbled twice in the same slots
- **THEN** the settled orientations are identical, and the RNG streams are untouched by either tumble

### Requirement: Taps resolve against the dice as drawn
The tumble renderer SHALL provide each die's tap rectangle as the screen-space bounds of the die's projected mesh under the tilted orthographic camera (`camera_tilt_deg`, art-direction spec), so tap forgiveness (throw-loop spec) measures from what the player sees. Each settled die's rectangle SHALL be at least `die_min_px` (126 px) on both sides at base resolution, and rectangles of settled dice SHALL NOT overlap.

#### Scenario: Tap the visible die
- **WHEN** the player taps the center of a settled die as drawn
- **THEN** that die locks

#### Scenario: Tap targets meet the minimum size
- **WHEN** a full 8-die tray has settled
- **THEN** every die's tap rectangle is at least 126 × 126 px and no two overlap

### Requirement: Die states read in the Smoke Room language
Die states SHALL read by shape and position, not colour alone.
- **Locked die:** it rises by `LOCK_LIFT` (current 0.12 world units) into a brass lock socket on the felt (`lock_socket.png`, `SOCKET_SIZE` 1.6 units), and shows a brass padlock badge at its front-right top corner (`padlock.png`, a billboard drawn over the die). It keeps its material colour.
- **Unlocked dice:** while any die is locked, unlocked live dice dim to `UNLOCKED_DIM` (0.88).
- **Dead slot (shattered Glass):** drawn at `DEAD_TINT` (0.38) with a crack overlay (`crack.png`, triplanar pass). It is static and never shows a socket. The throw screen floats "SHATTERED" over a die once, when it newly shatters.
- **Cascade flash:** the score cascade's per-die flash stays an amber pulse.
- **Shadows:** every die has a soft contact (blob) shadow. These states use unshaded or textured quads and sprites, not real-time shadows.

Hit rects and timing are unchanged.

#### Scenario: Locked die stays readable
- **WHEN** a Glass die is locked
- **THEN** it rises into its socket with a padlock badge and keeps its Glass look, and the unlocked dice dim

#### Scenario: Dead slot
- **WHEN** a Glass die shatters
- **THEN** it is drawn dark with a crack overlay, does not tumble, shows no socket, and "SHATTERED" floats once

