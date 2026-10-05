## 1. ScoreCascade helper

- [x] 1.1 Create `scripts/score_cascade.gd` — `RefCounted`, signals `finished`; constructor takes `(scene_node: Node, tumbler: DiceTumbler, result_label: Label, throw_score_label: Label, total_label: Label, config: ScoringConfig)`
- [x] 1.2 Implement `play(breakdown: ScoreBreakdown, locked_indices: Array[int]) -> void` — builds and runs the Tween chain: die flash → combo label scale-in → score tick-up → total tick-up → emit `finished`
- [x] 1.3 Implement `skip() -> void` — kills tween, stamps final values on all labels, emits `finished`

## 2. DiceTumbler flash support

- [x] 2.1 Add `flash_die(index: int, color: Color, duration: float) -> void` to `DiceTumbler` base (no-op default)
- [x] 2.2 Implement `flash_die` in `Viewport3DDiceTumbler` — tweens `_mats[index].albedo_color` to `color` then back to `COLOR_LOCKED`

## 3. ScoringConfig tunable

- [x] 3.1 Add `@export var cascade_duration_s: float = 0.8` to `scripts/scoring_config.gd` and update `resources/scoring_config.tres`

## 4. Wire into throw_scene

- [x] 4.1 In `_on_resolved()`: remove immediate label update and button re-enable; instead instantiate `ScoreCascade`, connect its `finished` signal to a new `_on_cascade_finished()` handler, call `play()`
- [x] 4.2 Add `_on_cascade_finished()` — re-enables THROW button (only if `_round.is_done` is false) and calls `_update_round_labels()`
- [x] 4.3 Verify round-won/lost paths still disable the button correctly (cascade fires before `add_score` triggers those signals, so order matters — check and fix if needed)

## 5. Tests

- [x] 5.1 Add GUT test `tests/test_score_cascade.gd` — instantiate with mock labels, call `skip()` immediately, assert labels show final values and `finished` fired
- [x] 5.2 Add scenario to existing smoke test: after resolution, verify THROW button is disabled; call `skip()` on the cascade; verify button re-enables

## 6. Verify on device

- [x] 6.1 Build APK, install on Pixel 9, play 3 throws — confirm die flash → combo label pop → score tick → total tick sequence plays each time
- [x] 6.2 Confirm THROW button stays disabled during cascade and re-enables correctly after
