# dice-materials Specification

## Purpose
Dice materials (Bone, Iron, Glass): per-die pip modifiers, slower tumbles, Glass dead slots, and how materials enter the run's bag through the shop.
## Requirements
### Requirement: DiceMaterial defines per-die scoring modifiers
Each die in the bag SHALL have a material type stored as a `StringName`. `DiceMaterial` is a `Resource` subclass with:
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

### Requirement: Slower materials delay the lock window
The tumble and re-roll phases SHALL last `tumble_duration_s × tumble_duration_factor`, using the largest factor among the dice drawn for the throw. The lock-window timer and the tumble animation SHALL use this same duration.

#### Scenario: Iron delays the lock window
- **GIVEN** base `tumble_duration_s` = 1.0 and a throw drawing only Iron dice
- **WHEN** 1.2 s of tumble have elapsed
- **THEN** the throw is still tumbling, and the lock window opens once 1.4 s have elapsed

### Requirement: Glass shatters on re-roll
When a Glass die is unlocked at the end of a lock window, it SHALL become a **dead slot**: it keeps its last face visually, is drawn dimmed and static during later tumbles, cannot be locked, and is excluded from `locked_order` at resolve time, contributing 0 pips.

#### Scenario: Glass die excluded from scoring
- **WHEN** a Glass die is unlocked during Window 1 and a re-roll occurs
- **THEN** the Glass die does not appear in `ThrowResult.locked_order` even after Window 3 force-lock

#### Scenario: Dead slot cannot be locked
- **GIVEN** a Glass die shattered at the end of Window 1
- **WHEN** the player taps it in Window 2
- **THEN** `lock_die` returns false, the die stays unlocked, and the tap resolves to the nearest live die instead

#### Scenario: Dead slot keeps its face
- **WHEN** the re-roll after Window 1 begins
- **THEN** each shattered Glass die stays still on its last face, dimmed, while live dice tumble

### Requirement: ThrowResult carries per-slot material data
`ThrowResult` SHALL include arrays parallel to `faces`:
- `pip_offsets: Array[int]`
- `pip_multipliers: Array[int]`
- `shattered: Array[bool]` — true = excluded from scoring

#### Scenario: Per-slot data matches drawn materials
- **WHEN** a throw of Iron dice resolves
- **THEN** every entry of `pip_offsets` is −1 and every entry of `pip_multipliers` is 1

### Requirement: M1 materials — Bone, Iron, Glass
The game SHALL ship three materials as `.tres` resources:
- **Bone** (cost: 0, built-in): pip_offset=0, pip_multiplier=1, shatter=false, tumble_factor=1.0. Default die.
- **Iron** (cost: 4): pip_offset=−1, pip_multiplier=1, shatter=false, tumble_factor=1.4. Easier to read, lower pips.
- **Glass** (cost: 6): pip_offset=0, pip_multiplier=2, shatter=true, tumble_factor=1.0. High reward, high risk.

#### Scenario: Materials load
- **WHEN** `bone.tres`, `iron.tres` and `glass.tres` are loaded from `res://resources/dice_materials/`
- **THEN** each is a `DiceMaterial` with the values above

### Requirement: DiceBag is run-scoped via RunCoordinator
`DiceBag` SHALL be created in `RunCoordinator.start_run()` and accessed by `ThrowScene` via `RunCoordinator.bag`. Shop can add dice to the bag via `RunCoordinator.bag.add(material_name)`.

#### Scenario: Bag survives scene changes
- **WHEN** a die is added to `RunCoordinator.bag` in the Shop and the run returns to `ThrowScene`
- **THEN** the throw draws from the same bag, including the new die

### Requirement: Shop offers dice
`ShopScene` SHALL include dice offers in its pool (up to 3 material types available). Buying a die calls `RunCoordinator.bag.add(material_name)`.

#### Scenario: Buying a die adds it to the bag
- **WHEN** the player buys an Iron die offer
- **THEN** `RunCoordinator.bag` holds one more Iron die and the gold is deducted

