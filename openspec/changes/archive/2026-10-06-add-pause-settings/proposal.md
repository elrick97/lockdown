## Why

UI/UX audit findings H3, A1, H5 and the hands-on pause-cover finding: there is no manual pause, no settings, no way to re-read how to play or see the combo list, and no way to abandon a run. The focus-loss cover is a blank screen with a lone "3". The Game Accessibility Guidelines expect reducible screen shake and adjustable game speed. Balatro ships game-speed and screen-shake options. PRD §4.6 already plans a haptics toggle (and later timer scale / Steady Mode). PRD trace: §2 *One thumb, one screen*; §4.6 accessibility.

## What Changes

- **⏸ button:** a small button in the HUD's top-right corner. It sits in the hard-reach zone on purpose: rare, and never hit while locking. Pressing it pauses through the existing focus cover, so the window restarts with a 3-2-1 on resume, as the spec already requires for focus loss. The cover now says "PAUSED" and shows the menu.
- **Pause menu:**
  - Resume;
  - How to play (the four lines, plus "Locks are final");
  - Combos (the 8 combos with example dice and base chips × mult);
  - Settings;
  - Abandon run (with a confirm, leads to the end panel as a loss).
- **Settings**, persisted locally in `user://settings.cfg` (plumbing):
  - Screen shake: 0 / 50 / 100%. It scales every shake and the tray nudge.
  - Cascade speed: 1× / 2× / instant. It scales the `FeedbackConfig` step times; instant means auto-skip.
  - Reduced motion: no shake, no stamp slam, shorter floats.
  - Haptics on / off.
- **Start screen:** a small Settings entry below PLAY.
- **Focus cover:** a "PAUSED — tap to resume" title above the countdown.

## Capabilities

### Modified Capabilities
- `throw-loop`: adds manual pause and the pause menu; focus cover copy.
- `run-flow`: adds abandon run.
- `ui-theme`: adds settings and the combos sheet.

## Impact

- New `scripts/settings.gd` (autoload, persisted) and `scripts/pause_menu.gd`; the throw scene and start scene are wired to them. A Blender pause and gear glyph.
- Settings only change presentation. Timer scale and Steady Mode stay M2 per PRD §4.6.
- Batched artifacts are acceptable for the settings plumbing per CLAUDE.md. The pause behaviour touches lock windows (reusing the existing focus-loss rule).
