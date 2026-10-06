## Why

UI/UX audit finding A3: every screen change (start → throw, throw → shop, shop → throw, end panel → new run or menu) is a hard cut through `change_scene_to_file`. A hard cut also exposes the 3D tray's first-frame warm-up. Polished games bridge screens with a short wipe that matches their world. Here that means smoke rolling across the table. PRD trace: §5 art direction (Smoke Room), §2 *Flow under pressure* (no jarring breaks in the loop).

## What Changes

- **SceneFader autoload:** every screen change goes through a new `SceneFader.change_to(path)`.
  - The current screen is covered by a full-screen smoke wipe over `transition_s` (0.22 s): dark warm smoke from the fog shader's noise texture, dissolving in with a soft edge.
  - The scene swaps under cover, and the new screen is revealed over `transition_s`.
  - Input is blocked while covered.
- **Reduced motion:** the wipe becomes a plain 0.15 s crossfade to dark.
- **Call sites:** `RunCoordinator`, the start screen, the throw screen and the shop call the fader instead of `change_scene_to_file`.
- **Tests:** headless tests and tools keep instant swaps through a `SceneFader.instant` flag, so nothing waits on animation.

## Capabilities

### Modified Capabilities
- `run-flow`: transitions between screens.
- `art-direction`: the transition uses the Smoke Room fog.

## Impact

- New `scripts/scene_fader.gd` (autoload) and a tiny wipe shader that reuses the fog noise. Five call sites change.
- No gameplay change. The playthrough and tests set `instant`.
