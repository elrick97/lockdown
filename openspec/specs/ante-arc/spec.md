# ante-arc Specification

## Purpose
The ante climb that gives a run its arc: per-ante target scores and how clearing or failing them advances or ends the run.

Named tunables on `AnteConfig` Resource (current M0 values): `targets` = **[150, 350, 700]** (3 antes). These are the minimum cumulative scores needed to clear each ante.

## Requirements

### Requirement: Ante arc drives run progression
`AnteArc` SHALL advance through a sequence of antes. After a round is won it checks whether more antes remain: if yes it advances to the next ante; if no it emits `run_won`. If a round is lost it emits `run_lost` immediately.

#### Scenario: Advance to next ante on win
- **WHEN** ante 1's round is won and antes remain
- **THEN** `AnteArc` advances to ante 2 (current_ante = 2) and provides the ante 2 target

#### Scenario: Run won after final ante
- **WHEN** the final ante's round is won
- **THEN** `run_won` fires and no further antes are started

#### Scenario: Run lost on round loss
- **WHEN** any round is lost
- **THEN** `run_lost` fires immediately regardless of which ante

### Requirement: Targets are data-driven via AnteConfig Resource
The ante target scores SHALL live in an `AnteConfig` Resource (`resources/ante_arc.tres`) as a named `targets: Array[int]` tunable. `AnteArc` reads from this resource at construction. Rebalancing M0 targets requires only editing the `.tres`, not touching script files.

#### Scenario: Targets loaded from resource
- **WHEN** `AnteArc` is constructed with the default `ante_arc.tres`
- **THEN** `target_for(1)` returns 150, `target_for(2)` returns 350, `target_for(3)` returns 700

#### Scenario: Custom targets in tests
- **WHEN** a test constructs `AnteConfig` with `targets = [10, 20]`
- **THEN** `AnteArc` uses those targets and a two-ante run can be driven headlessly

### Requirement: AnteArc is headless-safe
`AnteArc` SHALL be a `RefCounted` with no scene tree or autoload references. It SHALL be driven by `on_round_won() -> void` and `on_round_lost() -> void` calls from the throw scene.

#### Scenario: Headless full run
- **WHEN** a test creates `AnteArc` with 3 targets and calls `on_round_won` three times
- **THEN** `run_won` fires after the third call and `current_ante` equals 3

#### Scenario: Headless loss
- **WHEN** a test calls `on_round_lost` on ante 1
- **THEN** `run_lost` fires and `current_ante` remains 1

### Requirement: AnteArc signals
`AnteArc` SHALL emit:
- `ante_advanced(new_ante: int, target: int)` when a round is won and another ante begins
- `run_won` when the final ante is cleared
- `run_lost` when any round is lost

#### Scenario: ante_advanced carries correct data
- **WHEN** ante 1 is won and ante 2 begins
- **THEN** `ante_advanced` fires with `new_ante = 2` and `target = 350` (using default config)

### Requirement: AnteArc owned by RunCoordinator
`AnteArc` SHALL be created and owned by `RunCoordinator` (autoload) rather than by `ThrowScene` directly. `ThrowScene` SHALL receive the arc instance by reference from `RunCoordinator` on scene entry. This ensures arc state survives scene transitions to and from `ShopScene`.

#### Scenario: Arc state survives shop visit
- **WHEN** ante 1 clears, `ShopScene` loads and the player presses CONTINUE
- **THEN** `AnteArc.current_ante` is 2 when `ThrowScene` re-enters, and the arc's `run_won`/`run_lost` signals are still connected

### Requirement: ThrowScene signals ante cleared to RunCoordinator
When `AnteArc` emits `ante_advanced`, `ThrowScene` SHALL emit `ante_cleared(throws_left: int)` and disable the THROW button. `RunCoordinator` SHALL handle `ante_cleared` by crediting gold and transitioning to `ShopScene`.

#### Scenario: ante_cleared triggers shop transition
- **WHEN** `ThrowScene` emits `ante_cleared` with `throws_left = 1`
- **THEN** `RunCoordinator` credits `base_gold + 1 * gold_per_leftover` to `GoldLedger` and calls `get_tree().change_scene_to_file` for `ShopScene`

### Requirement: Run end is terminal
Once `run_won` or `run_lost` has fired, `AnteArc` SHALL ignore further `on_round_won` or `on_round_lost` calls without emitting additional signals.

#### Scenario: No double-fire after run end
- **WHEN** `on_round_won` is called again after `run_won` has already fired
- **THEN** no additional signal is emitted
