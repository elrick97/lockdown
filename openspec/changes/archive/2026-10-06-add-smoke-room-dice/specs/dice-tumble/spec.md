## ADDED Requirements

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
Locked dice SHALL show an amber ring (`palette_accent`) on the floor under the die and keep their material color. Dead slots (shattered Glass) SHALL be dimmed and static. The score cascade's per-die flash SHALL be an amber pulse. Every die SHALL have a soft contact (blob) shadow. These states SHALL use unshaded or textured quads, not real-time shadows.

#### Scenario: Locked die stays readable
- **WHEN** a Glass die is locked
- **THEN** an amber ring appears under it and the die keeps its Glass look (no tint)

#### Scenario: Dead slot
- **WHEN** a Glass die shatters
- **THEN** it is drawn dimmed, does not tumble, and shows no ring

## REMOVED Requirements

### Requirement: Selectable tumble renderer
**Reason**: The M0 spike chose the 3D SubViewport renderer (PRD §10.1) and the 2D renderer was cut. The seam no longer has two implementations, and Smoke Room dice are 3D-only.
**Migration**: None in code; `DiceTumbler` stays as the presentation base class. A future low-end fallback would need its own change, as PRD §10.1 already notes.
