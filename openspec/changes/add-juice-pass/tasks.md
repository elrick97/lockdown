## 1. Lock haptics

- [x] 1.1 In `_on_die_locked()` in throw_scene.gd: add `Input.vibrate_handheld(30)` after `_tumbler.lock_die()` call

## 2. Screen shake on combo

- [x] 2.1 Add `_screen_shake(amplitude, duration)` helper to throw_scene.gd
- [x] 2.2 Call `_screen_shake(8.0, 0.25)` in `_on_resolved()` when `breakdown.combos` is non-empty

## 3. Audio stubs

- [x] 3.1 Add `_sfx_lock` and `_sfx_combo` AudioStreamPlayer children created in `_ready()` (stream=null by default)
- [x] 3.2 Guard-play in _on_die_locked and _on_resolved (no-op until stream assets assigned)

## 4. Verify on device

- [ ] 4.1 Build + deploy; verify phone vibrates on each die lock; verify scene shakes briefly when combo lands in cascade
