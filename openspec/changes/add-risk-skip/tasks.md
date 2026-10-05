## 1. AnteConfig

- [x] 1.1 Add `risk_antes: Array[int]` and `skip_reward_gold: int` to `scripts/ante_config.gd`
- [x] 1.2 Update `resources/ante_arc.tres` with `risk_antes = [2]`, `skip_reward_gold = 3`

## 2. AnteArc

- [x] 2.1 Add `skip_round()` to `scripts/ante_arc.gd` (silent ante advance, no ante_advanced signal)
- [x] 2.2 Add `is_run_done() -> bool` accessor

## 3. RunCoordinator

- [x] 3.1 Add `on_risk_skipped()`: earn skip_reward_gold, call arc.skip_round(), transition to ShopScene

## 4. ThrowScene

- [x] 4.1 Create `_skip_button: Button` in `_ready()` (code-driven, Android safe)
- [x] 4.2 Position in `_apply_layout()`: bottom-left, mirror of THROW button
- [x] 4.3 Connect pressed to `RunCoordinator.on_risk_skipped`; show only on risk antes
- [x] 4.4 Hide skip button once a throw is started

## 5. Verify on device

- [ ] 5.1 Build + deploy; reach ante 2 — SKIP button visible; press it — earn 3g and go to Shop for ante 3
