# Spec: dice-materials (new capability)

### Requirement: DiceMaterial defines per-die scoring modifiers
Each die in the bag has a material type stored as a `StringName`. `DiceMaterial` is a `Resource` subclass with:
- `display_name: String`
- `pip_offset: int` — added to the die's face value before pip computation (Bone: 0, Iron: −1, Glass: 0)
- `pip_multiplier: int` — multiplies the adjusted pip value (Bone: 1, Iron: 1, Glass: 2)
- `shatter_on_reroll: bool` — die becomes a dead slot when re-rolled (Glass: true)
- `tumble_duration_factor: float` — multiplied by base tumble duration (Iron: 1.4, others: 1.0)
- `cost: int` — shop cost

#### Scenario: Iron pip offset applies
- **WHEN** an Iron die showing face 4 scores
- **THEN** it contributes `(4 + (−1)) × 1` = 3 pips, not 4

#### Scenario: Glass pip multiplier applies
- **WHEN** a Glass die showing face 5 scores
- **THEN** it contributes `(5 + 0) × 2` = 10 pips, not 5

#### Scenario: Iron face unchanged for combos
- **WHEN** two Iron dice both show face 6
- **THEN** the scoring engine detects a Pair (face 6 = face 6), independent of the pip offset

### Requirement: Glass shatters on re-roll
When a Glass die is unlocked at the end of a lock window, it SHALL become a **dead slot**: it keeps its last face visually but is excluded from `locked_order` at resolve time and contributes 0 pips.

#### Scenario: Glass die excluded from scoring
- **WHEN** a Glass die is unlocked during Window 1 and a re-roll occurs
- **THEN** the Glass die does not appear in `ThrowResult.locked_order` even after Window 3 force-lock

### Requirement: ThrowResult carries per-slot material data
`ThrowResult` SHALL include:
- `pip_offsets: Array[int]` — parallel to `faces`
- `pip_multipliers: Array[int]` — parallel to `faces`
- `shattered: Array[bool]` — parallel to `faces`; true = excluded from scoring

### Requirement: M1 materials — Bone, Iron, Glass
- **Bone** (cost: 0, built-in): pip_offset=0, pip_multiplier=1, shatter=false, tumble_factor=1.0. Default die.
- **Iron** (cost: 4): pip_offset=−1, pip_multiplier=1, shatter=false, tumble_factor=1.4. Easier to read, lower pips.
- **Glass** (cost: 6): pip_offset=0, pip_multiplier=2, shatter=true, tumble_factor=1.0. High reward, high risk.

### Requirement: DiceBag is run-scoped via RunCoordinator
`DiceBag` SHALL be created in `RunCoordinator.start_run()` and accessed by `ThrowScene` via `RunCoordinator.bag`. Shop can add dice to the bag via `RunCoordinator.bag.add(material_name)`.

### Requirement: Shop offers dice
`ShopScene` SHALL include dice offers in its pool (up to 3 material types available). Buying a die calls `RunCoordinator.bag.add(material_name)`.
