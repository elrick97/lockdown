# Tasks: add-throw-loop

## 1. Headless core

- [x] 1.1 `scripts/throw_config.gd` (`ThrowConfig`, `Resource`): tunables `tumble_duration_s` 1.5, `lock_window_duration_s` 2.5, `tap_forgiveness_radius_px` 96, `resume_countdown_s` 3, `draw_size` 6, `starting_bag_size` 8; default `resources/throw_config.tres`
- [x] 1.2 `scripts/dice_bag.gd` (`DiceBag`, `RefCounted`): bag of standard dice, draw via `bag` stream (no replacement within throw, tray cap 8 clamp, short-bag draw), return on resolve
- [x] 1.3 `scripts/throw_controller.gd` (`ThrowController`, `RefCounted`): state machine Draw→Tumble→Lock1→Reroll→Lock2→Reroll→Lock3→ForceLock→Resolved; inputs `tick(delta)`/`lock_die(index)`/`restart_window()`; signals `window_started`, `die_locked`, `reroll`, `resolved`
- [x] 1.4 Faces from `dice` stream at tumble/re-roll start; locked dice keep faces; force-lock at window 3 expiry; early resolve when all locked (credit unstarted windows at full duration)
- [x] 1.5 Per-window remaining-time recording on the resolve payload (locked faces, lock order, 3 window times)

## 2. Headless tests (GUT)

- [x] 2.1 `DiceBag` tests: draw size, cap clamp, short bag, return-on-resolve, bag-stream determinism
- [x] 2.2 State machine tests: full 3-window sequence; partial locks re-roll only unlocked dice; lock irreversibility; force-lock; early resolution + full-duration credit
- [x] 2.3 Timing tests: 1/30 vs 1/60 delta feeds give equal effective durations; remaining-time values correct on expiry and on all-locked; `restart_window()` keeps locks and zeroes the accumulator
- [x] 2.4 Determinism test: same seed + same scripted lock inputs → identical resolve payload, headless

## 3. Scene layer (gray-box)

- [x] 3.1 `scenes/throw/throw_scene.tscn` + script: numbered placeholder squares (≥132 px at base res), tray layout in middle 50% of portrait screen, drives controller via `_process` tick
- [x] 3.2 Tap input: screen-space nearest-unlocked-die resolution within `tap_forgiveness_radius_px` → `lock_die(index)`; locked-die visual state; same-frame lock feedback
- [x] 3.3 Placeholder tumble/re-roll animation (`tumble_duration_s`) animating to predetermined faces; window timer drain bar
- [x] 3.4 Throw button + resolve readout (locked faces, per-window times as raw text) so a throw is playable end-to-end
- [x] 3.5 Focus-loss handling: pause + opaque tray cover on `NOTIFICATION_APPLICATION_FOCUS_OUT`/`APPLICATION_PAUSED`, 3-2-1 countdown on resume, `restart_window()`
- [x] 3.6 Wire `main.tscn` to open the throw scene; verified end-to-end via in-tree GUT smoke test (human mouse pass: pending user)

## 4. Wrap up

- [x] 4.1 Full headless suite green via `tools/run_tests.ps1` (19 tests, 180 asserts)
- [x] 4.2 Update TASKS.md (tick bag/RNG-law/tumble/lock-window/focus-loss/re-roll boxes with `add-throw-loop`)
- [x] 4.3 Commit
