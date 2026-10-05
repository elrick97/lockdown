# charm-effect Specification

## Purpose
The data-driven charm framework: the CharmEffect resource and its four hooks, the context snapshot it reads, and the inventory slot cap.

## Requirements

### Requirement: CharmEffect is a Resource base class with four hooks
`CharmEffect` SHALL extend `Resource`. It SHALL expose four methods with default no-op implementations: `on_throw(ctx: CharmContext) -> void`, `on_window(window_index: int, ctx: CharmContext) -> void`, `on_lock(die_index: int, face: int, window_index: int, ctx: CharmContext) -> void`, and `on_score(breakdown: ScoreBreakdown, ctx: CharmContext) -> void`. Each concrete charm is a GDScript that extends `CharmEffect` and overrides whichever hooks it needs. Adding a charm SHALL NOT require editing any engine script.

#### Scenario: No-op base hooks
- **WHEN** a bare `CharmEffect` instance is constructed and all four hooks are called
- **THEN** no error is raised and `ScoreBreakdown` fields are unchanged

#### Scenario: Concrete charm overrides on_score
- **WHEN** a charm that overrides `on_score` is in the inventory and scoring runs
- **THEN** the charm's `on_score` implementation fires and may modify `breakdown.charm_chips` or `breakdown.charm_mult`

### Requirement: CharmEffect carries display metadata
Each `CharmEffect` SHALL expose `@export var display_name: String`, `@export var description: String`, and `@export var cost: int`. These are readable by `ShopScene` without requiring knowledge of the concrete subclass.

#### Scenario: Metadata accessible generically
- **WHEN** `ShopScene` iterates the charm pool and reads `display_name` and `cost` from each entry
- **THEN** the correct strings are returned for each charm without downcasting

### Requirement: CharmContext is an immutable snapshot
`CharmContext` SHALL be a `RefCounted` built fresh before each hook dispatch. It SHALL expose: `locked_faces: Array[int]` (copy of locked die faces), `locked_windows: Array[int]` (which window each die was locked in; 0 = not yet locked), `window_times: Array[float]` (accumulated remaining-time per window so far), `current_window: int` (0 during `on_throw`; 1–3 during `on_window`/`on_lock`), `die_index: int` (index of the die being locked; -1 otherwise), `round_total: int` (score accumulated this round before this throw), and `throw_number: int`. Charms SHALL read context fields only and SHALL NOT mutate them.

#### Scenario: Snapshot isolation
- **WHEN** a charm modifies the `locked_faces` array obtained from context
- **THEN** the engine's internal locked state is unaffected (the array is a copy)

### Requirement: CharmInventory enforces a five-slot cap
`CharmInventory` SHALL be a `RefCounted` owning an ordered `Array[CharmEffect]` with a maximum of 5 entries. It SHALL expose `add_charm(c: CharmEffect) -> bool` (returns `false` if full), `iter_charms() -> Array[CharmEffect]` (defensive copy), and `is_full() -> bool`. `RunCoordinator` SHALL own one `CharmInventory` instance and reset it in `start_run()`.

#### Scenario: Add up to five charms
- **WHEN** `add_charm` is called five times with distinct effects
- **THEN** all five are accepted and `is_full()` returns `true`

#### Scenario: Sixth charm rejected
- **WHEN** `add_charm` is called on a full inventory
- **THEN** it returns `false` and the inventory remains unchanged

#### Scenario: Reset on new run
- **WHEN** `RunCoordinator.start_run()` is called
- **THEN** `CharmInventory` is replaced with a fresh empty instance

### Requirement: RngService exposes a shop stream
`RngService` SHALL provide a dedicated `shop` stream (separate from `dice` and `core`) initialized from the same run seed with a fixed offset. `ShopScene` SHALL use `RngService.shuffle_shop()` to shuffle the charm offer pool so shop offers do not consume entropy from the `dice` stream.

#### Scenario: Shop shuffle does not affect dice outcomes
- **WHEN** two runs use the same seed but one re-rolls the shop offer once
- **THEN** the dice faces in subsequent throws are identical between the two runs
