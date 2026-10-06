## Why

UI/UX audit finding C1 (P0): a locked die only gets a thin amber ring on the felt. The die itself is unchanged, so in a 2.5 s window it is hard to see which dice are locked, and a lock is permanent. Shattered Glass dice are tinted grey and read as "darker glass", not "gone". Dicey Dungeons-style seated dice and Balatro's raised selected cards both use shape and position, not just colour (Game Accessibility Guidelines: never rely on colour alone). PRD trace: §2 *Flow under pressure*, *One thumb, one screen*.

## What Changes

- **Locked die:**
  - It lifts (+0.12 world units) and settles into a Blender-rendered brass lock socket on the felt, which replaces the thin ring.
  - A small padlock badge sits at the die's front corner, rendered in Blender as a brass padlock.
- **Figure and ground:** while any die is locked, unlocked dice dim to about 88%, so the locked set pops.
- **Shattered (dead) die:** fully desaturated, with a crack overlay on the die and a one-time "SHATTERED" float. The shape cue makes it colour-blind safe.
- **Tumbler code:** all of this is presentation-only in the tumbler (`lock_die`, `mark_dead`). Hit rects and timing are unchanged.

## Capabilities

### Modified Capabilities
- `dice-tumble`: lock and dead visuals.
- `art-direction`: socket, padlock and crack assets.

## Impact

- Blender: `lock_socket.png`, `padlock.png`, `crack.png` in `assets/dice/`, within budget.
- `viewport_3d_dice_tumbler.gd`.
- Tests: a locked die is raised and shows its socket and padlock; unlocked dice dim; the dead die has its crack.
- Desktop frame time is re-checked with `perf_dice.gd`.
