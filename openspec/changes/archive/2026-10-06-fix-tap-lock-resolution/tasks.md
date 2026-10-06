## 1. Fix

- [x] 1.1 `_try_lock_at` resolves to the nearest die of any state; locked/shattered → `deny_die`
- [x] 1.2 `deny_die` wiggle with a remembered home position (no drift on repeated taps)

## 2. Verification

- [x] 2.1 Tests: locked die never forgives to its neighbour (centre + edge), gap near a locked die denied, near miss still snaps, wiggle returns home
- [x] 2.2 GUT green; playthrough green
