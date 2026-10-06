## Decisions

### D1: Pause reuses the focus-loss pause
`open_pause` sets `_menu_open` and calls `_on_focus_lost`. `_on_focus_returned` ignores focus-in while the menu is open. Resume picks the countdown path only when a window could be running. This keeps the lock-window rule ("time never runs while you can't play") in one place.

### D2: Menu as pages on one card
`PauseMenu` (`process_mode = ALWAYS`) rebuilds its content per page. `_fit` sizes the card to the page and pins it to the bottom (one thumb). The same component is used on the start screen in settings-only mode.

### D3: Settings scale presentation at the source
- Shake: `_screen_shake` and `_nudge_tray` multiply by `Settings.shake_scale()`.
- Score speed: the cascade tween's `speed_scale`, or `skip()` for Instant.
- Reduced motion: `ScoreHud.slam` uses scale 1.0, and the start screen skips its idle tweens.
- Haptics: the lock vibrate is guarded.

`ScoreHud` looks `Settings` up at runtime, because tools compile it before autoloads exist.

### D4: Persistence
A `ConfigFile` in `user://` is a plain local file (no dependency). Tests set `persist = false`.
