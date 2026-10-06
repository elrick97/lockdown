## Why

UI/UX audit findings C5, C6, D1 and D2 (`docs/uiux-audit-2026-10-06.md`):
- **C6:** every lock shook the whole screen, HUD text included. Juice is strongest when reserved for big moments (Nijman, "The art of screenshake").
- **C5:** the timer urgency pulse ran at about 4.8 Hz. That is above the 3-flashes-per-second guideline (Game Accessibility Guidelines; WCAG 2.3.1) and against the owner's "never flicker" rule.
- **D1:** floating numbers piled up over the plaque values.
- **D2:** the combo stamp stayed parked over the dice after the score landed.

Presentation only. PRD trace: §2 *Jackpot payoff* without noise; *Readable depth*.

## What Changes

- **Lock feedback:** only the dice tray nudges (`lock_shake_px` / `lock_shake_s`). Full-screen shake is kept for combo tiers and TARGET HIT.
- **Timer urgency:**
  - The pulse runs at `urgency_pulse_hz` (2 Hz).
  - The seconds left show as a number at the bar's end, so urgency isn't conveyed by colour alone.
- **Plaque floats:**
  - They spawn just above the plaques and rise only `PLAQUE_RISE` (50 px), so they never cover a value or reach the HUD panel.
  - Deltas landing on the same plaque while its float is alive merge into one climbing number (Hades / Vampire Survivors rule).
  - Die floats stack by `float_stack_px` instead of overlapping.
- **Combo stamp:** after `stamp_hold_s` (0.55 s) it lifts off the dice, shrinks and fades, leaving the board readable.

## Capabilities

### Modified Capabilities
- `throw-loop`: lock feedback, timer urgency.
- `score-cascade`: adds float readability and the stamp lift.

## Impact

- `throw_scene.gd`, `score_hud.gd`, `score_cascade.gd`, `feedback_config.gd`.
- No scoring or timing change.
