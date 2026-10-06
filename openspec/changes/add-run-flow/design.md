## Context

`project.godot` runs `scenes/main.tscn`, which instances the throw scene. `ThrowScene._ready` starts a run if none exists. `AnteArc` emits `run_won`/`run_lost`; the throw scene shows a status text and disables THROW. `RunCoordinator` (autoload) owns run state; `end_run()` is never called. Layout is done in code (Android anchor gotcha).

## Decisions

### D1: Start scene is the main scene
New `scenes/start/start_scene.tscn` (root `Control` + script, layout in code), set as `run/main_scene`. `main.tscn` stays the throw-scene wrapper and is no longer the entry point. The mark is drawn with `_draw()` (a rounded die outline with five pips and a bolt, brass/amber), so it needs no asset and carries no text.

### D2: `RunCoordinator.new_run(seed := 0)`
Calls `end_run()` then `start_run(seed)`, and resets `best_throw`. PLAY and NEW RUN both use it, so the reset path is a single function under test. `record_throw(score)` keeps the maximum; the throw scene calls it in `_on_cascade_finished` before the round resolves.

### D3: End panel built in code on the throw scene
`_build_end_panel()` creates a full-screen dim `ColorRect` with a centered panel (title, three summary lines) and a bottom button row (NEW RUN, MENU), hidden until `_on_run_won`/`_on_run_lost`. It sits above the tray and below the focus cover, so focus loss still covers everything. Ante reached is `arc.current_ante` of `ante_count`.

### D4: Focus rules
The start screen has no timers, so it doesn't implement focus-loss pausing; the throw scene's protection is unchanged.

## Risks / Trade-offs

- **Tests that instance the throw scene directly** keep working: `_ready` still starts a run if none exists.
