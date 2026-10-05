## 1. AnteConfig resource

- [x] 1.1 Add `round_names: Array[String]`, `boss_antes: Array[int]`, `boss_window_scale: float` to `scripts/ante_config.gd`
- [x] 1.2 Update `resources/ante_arc.tres` with `round_names = ["Open", "Risk", "Boss"]`, `boss_antes = [3]`, `boss_window_scale = 0.5`

## 2. ThrowScene

- [x] 2.1 Add `_effective_window_s: float` field; compute it in `_ready()` from ante config
- [x] 2.2 Replace `_config.lock_window_duration_s` with `_effective_window_s` in timer bar fraction and score call
- [x] 2.3 Update ante label format to include round type name
- [x] 2.4 `_make_controller()` helper duplicates config with overridden window duration; signals connected inside helper

## 3. Tests

- [x] 3.1 Add headless test: ante 3 controller uses halved duration

## 4. Verify on device

- [x] 4.1 Verified locally 2026-10-05 (headless GUT 155/155 + desktop playthrough `tools/playthrough.gd`, 0 failed checks): ante 3 shows 'BOSS ROUND' and the lock window measures ~1.2 s (half of 2.5 s).
