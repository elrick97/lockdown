## Why

Shattered Glass dice are dead slots: they can't be locked (dice-materials spec). The throw-loop rule "resolve early when every tray die is locked" counts them as unlocked dice, so once a Glass die has shattered the throw can never end early. Two things go wrong:

1. **Speed goes unrewarded.** A player who locks every live die quickly still waits out every remaining window, and Heat drops to ×1.0. The same play without Glass earns ×1.3 (case C below). Shattering already costs the die; it shouldn't also wipe out the speed reward on the rest of the throw.
2. **Dead time.** When a re-roll leaves nothing lockable (every die is either locked or shattered), the player watches about 8 s of empty re-rolls and windows with nothing to do.

Found during local verification of `add-dice-materials`; flagged instead of fixed because it changes Heat outcomes. PRD trace: §3.2 (the throw), §2 pillar *Flow under pressure*.

**Pillars served:** *Flow under pressure*: speed is rewarded, and no dead time where the player can do nothing. *Readable depth*: Glass stays a clear trade (risk the die, keep your tempo).

## What Changes

- **"Every die is locked" becomes "every die is locked or dead."** Locking the last live die ends the window and resolves the throw immediately, crediting the rest of that window plus the full duration of the later windows. That's the existing rule, applied correctly when shattered dice are present.
- **A re-roll that leaves nothing lockable resolves the throw immediately**, instead of running empty windows. **Decision for you: what do the skipped windows earn?**
  - **No credit (recommended):** the skipped windows count as 0 s remaining, so Heat is exactly what it is today, minus the wait. Full credit stays tied to the player actually locking everything.
  - **Full credit:** the skipped windows count as full duration, like the existing early-resolution rule. Letting Glass shatter would then *raise* Heat from ×1.0 to ×1.33 (cases A, B), which rewards the risky outcome.

### Heat impact (heat_min 1.0, heat_max 1.5, window 2.5 s)

| Case | Today | Full credit | No credit |
|---|---|---|---|
| A: 1 Glass locked in W1, 5 shatter, nothing left to lock | ×1.000 (+~8 s idle) | ×1.333 | ×1.000 |
| B: 4 Bone locked by 1.2 s, 2 Glass shatter, nothing left | ×1.000 (+~8 s idle) | ×1.333 | ×1.000 |
| C: 1 Glass shatters, last 2 Bone locked 0.5 s into W2 | ×1.000 | ×1.300 | ×1.300 |
| Reference: case C with no Glass (unchanged) | ×1.300 | ×1.300 | ×1.300 |

Throws without shattered dice are unaffected. CLAUDE.md asks for balance-sim before/after numbers on Heat changes. The sim is an M2 item and doesn't exist yet, so these hand-computed cases from the Heat formula stand in for it. The apply step will verify them with headless tests.

## Capabilities

### New Capabilities
- None.

### Modified Capabilities
- `throw-loop`: the early-resolution scenario and per-window time recording count dead slots as done; new scenario for a re-roll that leaves nothing lockable.

## Impact

- `scripts/throw_controller.gd`: the all-locked check ignores dead slots; `_begin_reroll` resolves when nothing is lockable; the recorded window times follow the chosen credit rule.
- Tests in `tests/test_dice_materials.gd` / `tests/test_throw_controller.gd`; the desktop playthrough adds a dead-slot case.
- No change to the Heat formula, `ScoringConfig` tunables, or throws without Glass.

## Non-goals

- Changing the Heat formula or any Heat tunable.
- Changing Glass itself (shatter rule, ×2 pips, cost).
- Any presentation work beyond what resolving early already shows (the cascade plays as usual).
