## MODIFIED Requirements

### Requirement: AnteConfig carries risk-skip parameters
`AnteConfig` SHALL include:
- `risk_antes: Array[int]` — 1-based ante indices where a skip offer is shown (default: `[2]`)
- `skip_reward_gold: int` — gold earned when the player skips the risk round (current value: `3`)

#### Scenario: Skip reward configured
- **WHEN** `AnteConfig` has default values
- **THEN** `skip_reward_gold` is 3 and `risk_antes` is `[2]`

### Requirement: Risk round can be skipped for reduced gold
`AnteArc.skip_round()` SHALL behave identically to `on_round_won()`: advance the ante or emit `run_won`. `RunCoordinator.on_risk_skipped()` SHALL earn `skip_reward_gold` before calling `skip_round()`.

#### Scenario: Skip earns gold and advances
- **WHEN** the player presses SKIP on ante 2
- **THEN** `GoldLedger.gold` increases by `skip_reward_gold` and `current_ante` becomes 3
