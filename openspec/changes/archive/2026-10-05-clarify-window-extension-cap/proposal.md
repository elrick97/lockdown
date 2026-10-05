## Why

Spark ("adds 0.5 s") and Freeze Timer ("extends the current window by 2 s") both work by giving back elapsed window time, so neither can push the remaining time above the full window length (2.5 s, or 1.25 s on a boss ante). Pressed early in a window, Freeze gives back only the time already spent. The specs' examples happen to fit the cap, but the wording reads as an unconditional +2 s. The owner ruled (2026-10-05) to **keep the cap**. This change makes the spec say so, so the code and spec can't be read as disagreeing. PRD trace: §3.2 (lock windows), §4.3 (Spark).

**Pillars served:** *Flow under pressure*: a window never grows beyond its base length, so stacking extensions can't remove the pressure. *Readable depth*: the rule a player discovers ("it refills the timer") is the rule in the spec.

## What Changes

- **Spark (throw-loop spec):** "adds 0.5 s, up to the full window length".
- **Freeze Timer (trinkets spec):** "extends the current window by up to 2 s, never beyond its full length". Each gets a scenario for pressing it early.
- **No code change.** `ThrowController.freeze_window()` already clamps at the full window. The new scenarios get headless tests that pin the behavior.

## Capabilities

### New Capabilities
- None.

### Modified Capabilities
- `throw-loop`: the Spark requirement states the cap and gains an early-lock scenario.
- `trinkets`: the M1 trinkets requirement states Freeze Timer's cap and gains an early-press scenario.

## Impact

- Specs only, plus two headless tests (`tests/test_carving.gd`, `tests/test_trinkets.gd`) asserting the cap: Spark at 0.2 s elapsed → 2.5 s remaining; Freeze at 0.5 s elapsed → 2.5 s remaining.
- No change to Heat, tunables, or any code path.

## Non-goals

- Changing the cap, the 0.5 s / 2 s amounts, or making extensions carry over to later windows.
