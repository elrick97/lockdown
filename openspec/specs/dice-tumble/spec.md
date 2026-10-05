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

### Requirement: Selectable tumble renderer
The presentation SHALL expose a selectable tumble renderer so the same seeded throw can be rendered by either spike approach (2D sprite or 3D SubViewport) without changing gameplay code. Renderer selection SHALL live in the presentation layer only; `ThrowController` and scoring SHALL be unaffected by the choice.

#### Scenario: Swap renderer, same outcome
- **WHEN** the active tumble renderer is switched between the 2D and 3D approaches for the same seed
- **THEN** the faces, lock behavior, and score are identical; only the on-screen presentation differs

### Requirement: Locked dice do not tumble
Dice locked in a previous window SHALL retain their faces and SHALL NOT animate during a re-roll tumble; only unlocked dice tumble to new predetermined faces.

#### Scenario: Re-roll tumbles only unlocked dice
- **WHEN** a re-roll tumble begins with some dice locked
- **THEN** the locked dice are visually static on their existing faces and only the unlocked dice animate
