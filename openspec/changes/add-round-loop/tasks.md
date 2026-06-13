# Tasks: add-round-loop

## 1. Config + data model

- [x] 1.1 `scripts/ante_config.gd` (`AnteConfig`, `Resource`): `@export var targets: Array[int]` and `@export var throws_per_round: int = 3`; default `resources/ante_arc.tres` with targets `[150, 350, 700]`

## 2. RoundState (headless)

- [x] 2.1 `scripts/round_state.gd` (`RoundState`, `RefCounted`): signals `round_won`, `round_lost`; `add_score(score: int)` accumulates toward target, fires signal once, ignores calls after signal; `reset(target: int)` for reuse
- [x] 2.2 `scripts/round_state.gd`: expose `current_throw: int`, `total: int`, `target: int`, `is_done: bool` read-only properties

## 3. AnteArc (headless)

- [x] 3.1 `scripts/ante_arc.gd` (`AnteArc`, `RefCounted`): constructor takes `AnteConfig`; signals `ante_advanced(new_ante: int, target: int)`, `run_won`, `run_lost`; `on_round_won()` and `on_round_lost()` drive transitions; `target_for(ante: int) -> int` helper
- [x] 3.2 `scripts/ante_arc.gd`: `current_ante: int` read-only property; run-end terminal guard (ignore calls after `run_won`/`run_lost` fired)

## 4. Headless tests

- [x] 4.1 `tests/test_round_state.gd`: win on throw 1 (score ≥ target immediately), win after accumulation (throw 1 + throw 2), lose on throw 3, signal fires exactly once, `add_score` ignored after done, `reset()` reinitialises correctly
- [x] 4.2 `tests/test_ante_arc.gd`: advance through all 3 antes → `run_won`; `on_round_lost` on ante 1 → `run_lost`; `ante_advanced` signal carries correct `new_ante` and `target`; no double-fire after run end; custom 2-ante config drives a full headless run

## 5. Scene integration

- [x] 5.1 `throw_scene.gd`: create `AnteConfig` (from .tres) + `AnteArc` + `RoundState` on `_ready`; connect `resolved` signal → `_on_resolved` passes `breakdown.final_score` to `round_state.add_score`; connect `round_won` → `_on_round_won`; connect `round_lost` → `_on_round_lost`
- [x] 5.2 `throw_scene.gd`: on `round_won` call `ante_arc.on_round_won()`; on `round_lost` call `ante_arc.on_round_lost()`; connect `ante_advanced` → reset `RoundState` with new target and re-enable THROW button; connect `run_won` / `run_lost` → show terminal message, disable THROW
- [x] 5.3 UI labels: add `AnteLabel` (e.g. "Ante 1 / 3"), `ThrowLabel` ("Throw 2 / 3"), `TotalLabel` ("Total: 247 / 350") to the scene; update all three on every resolved throw and on ante advance

## 6. Smoke test + TASKS update

- [x] 6.1 Extend `tests/test_throw_scene_smoke.gd` (or add `test_round_smoke.gd`): drive a fast-config full throw sequence through all 3 antes using sped-up tunables; assert `run_won` or `run_lost` fires and the ante/throw labels reflect final state
- [x] 6.2 Update `TASKS.md`: tick "Round loop" and "Minimal ante climb" boxes with `add-round-loop`
- [ ] 6.3 Run full headless suite via `tools/run_tests.ps1`; confirm all tests green
- [ ] 6.4 Commit

## 7. On-device verification

- [ ] 7.1 Launch game windowed; play a full 3-ante run to completion (win or lose); confirm ante counter advances, throw budget decrements, running total accumulates, and WIN/LOSE message appears correctly
