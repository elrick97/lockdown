## Why

UI/UX audit finding A1: the four start-screen lines are the only teaching, shown once. The audit recommends contextual one-line coach marks the first time each concept appears, as a cheap bridge to the M3 tutorial (Game Accessibility Guidelines: remind players of objectives during play; teach by doing). PRD trace: §2 *Readable depth*; M3 "Tutorial" item (this is not the tutorial, just first-occurrence hints).

## What Changes

- **Tips:** a small coach-mark bubble (leather plaque with a brass pointer) appears once per player, the first time each moment happens. It is anchored to the relevant element, and a tap dismisses it.

| Moment | Tip | Anchor |
|---|---|---|
| First lock window | "Tap a die to lock it. Locks are final." | the tray |
| First lock | "Locked! The rest re-roll when the timer runs out." | the locked die |
| First resolve with a combo | "PAIR = 10 chips × 1 mult. Bigger combos score more." | the plaques |
| First time HEAT drops below max | "Heat: lock sooner for a bigger multiplier." | the HEAT plaque |
| First shop | "Charms change how you score. Tap any icon to read it." | the offers |
| First boss | "Boss: lock windows are half as long." | the timer |

- **Never blocks play:** tips never pause the game or eat a tap. They are input-transparent; the tap still reaches the die or button.
- **Saved once seen:** seen tips are stored in `user://settings.cfg` next to the settings.
- **Settings:** a "Show tips again" entry resets them, and "Tips: On / Off" turns them off.

## Capabilities

### Modified Capabilities
- `ui-theme`: adds first-time tips and their settings.

## Impact

- New `scripts/coach_mark.gd`, plus small hooks in the throw scene and shop. `Settings` gains `tips_enabled` and `seen_tips`.
- Tests: each tip shows once, persists as seen, never blocks a die tap, and respects the toggle.
