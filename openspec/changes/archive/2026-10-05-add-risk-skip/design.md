# Design: add-risk-skip

## Risk ante identification

`AnteConfig` gets:
- `risk_antes: Array[int] = [2]` — 1-based antes where skip is offered
- `skip_reward_gold: int = 3` — gold earned on skip

## ThrowScene changes

Add a `_skip_button: Button` node. In `_apply_layout()` position it above the THROW button.

On `_ready()`, set visibility: `_skip_button.visible = _ante_config.risk_antes.has(_arc.current_ante)`.

On press: call `RunCoordinator.on_risk_skipped()`.

The button is only visible during the risk ante, while the throw session is idle (hidden once a throw starts).

## RunCoordinator changes

New method `on_risk_skipped()`:
- Earns `shop_config` → actually earns `ante_config.skip_reward_gold` gold via `GoldLedger.earn()`
- Calls `arc.skip_round()` to advance past the risk ante
- Transitions to ShopScene

`AnteArc` gets `skip_round()`:
- Same effect as `on_round_won()` — advances ante, emits `ante_advanced` or `run_won`

## Skip button layout

Position at bottom-left, THROW at bottom-right, mirroring the Shop's REROLL/CONTINUE layout.
