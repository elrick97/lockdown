## MODIFIED Requirements

### Requirement: ThrowScene signals ante cleared to RunCoordinator
When `AnteArc` emits `ante_advanced`, `ThrowScene` SHALL emit `ante_cleared(throws_left: int)` and disable the THROW button. `RunCoordinator` SHALL handle `ante_cleared` as follows:
1. Credit the round's gold.
2. Apply interest once for the coming shop visit.
3. Emit `cashout_ready` with the itemised breakdown.

The throw screen shows the round-cleared panel, and its CONTINUE calls `RunCoordinator.go_to_shop()`, which transitions to `ShopScene`.

#### Scenario: ante_cleared leads to the shop through the cash-out
- **WHEN** `ThrowScene` emits `ante_cleared` with `throws_left = 1`
- **THEN** `RunCoordinator` credits `base_gold + 1 * gold_per_leftover`, applies interest and emits `cashout_ready`; the shop loads when the player presses CONTINUE

### Requirement: Risk round can be skipped for reduced gold
`AnteArc.skip_round()` SHALL behave identically to `on_round_won()`: advance the ante or emit `run_won`. `RunCoordinator.on_risk_skipped()` SHALL do the following:
1. Earn `skip_reward_gold` before calling `skip_round()`.
2. If the run continues, apply interest for the coming shop visit, like any other shop visit (gold-economy spec).
3. Emit `cashout_ready` titled "ROUND SKIPPED".

#### Scenario: Skip earns gold and advances
- **WHEN** the player presses SKIP on ante 2 holding 6 gold
- **THEN** gold becomes 6 + 3 = 9 plus interest (11), `current_ante` becomes 3, and the round-skipped cash-out shows before the shop
