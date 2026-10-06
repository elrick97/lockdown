## Why

The UI/UX audit (`docs/uiux-audit-2026-10-06.md`, finding C3) found an irreversible mis-lock. Tap forgiveness snapped to the nearest *unlocked* die within 96 px and skipped locked ones. The gap between dice is about 90 px, so re-tapping near the edge of an already-locked die could lock its neighbour, and locks can't be undone. Taps on a locked die also gave no feedback at all. PRD trace: §2 *Flow under pressure* (one wrong lock in a 2.5 s window is a run-losing frustration); throw-loop tap-to-lock.

## What Changes

- **Nearest die of any state:** a tap resolves to the nearest die in any state (unlocked, locked or shattered) within `tap_forgiveness_radius_px`.
  - An unlocked die locks, as before.
  - A locked or shattered die gets a short "denied" wiggle and nothing locks.
  - Forgiveness in the gaps still snaps to an unlocked die when that die is the nearest.
- **Denied wiggle:** `DiceTumbler.deny_die(index)` plays a side-to-side wiggle and always returns the die to its resting position, even on repeated taps.

## Capabilities

### Modified Capabilities
- `throw-loop`: tap-to-lock forgiveness resolution, plus denied feedback.

## Impact

- `throw_scene.gd` (`_try_lock_at`) and the tumbler's `deny_die`.
- Timing, scoring and the radius tunable are unchanged.
