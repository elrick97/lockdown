## ADDED Requirements

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
