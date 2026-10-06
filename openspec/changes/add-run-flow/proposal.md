## Why

The game has no start and no end. It opens straight into ante 1 with no explanation. When a run is won or lost, the throw screen says "YOU WIN!" / "GAME OVER." and disables THROW, leaving no way to play again short of reloading the page. `RunCoordinator.end_run()` exists but nothing calls it. For a public web MVP (owner goal, 2026-10-06), a stranger needs to understand the first minute and replay without help. That's also the M1 gate condition ("a stranger can play one full ante unaided"). PRD trace: §2 *Readable depth*, §3.1 run structure, §8 success metrics (second-run starts).

**Pillars served:** *Readable depth*: a 20-second how-to before the first throw. *Collect & unlock*: the end screen shows what the run achieved and invites the next run.

## What Changes

- **Start screen** (new `scenes/start/start_scene.tscn`, the new main scene): a pictogram mark (die + bolt, no name or logo: PRD Q4, art-direction spec), a short how-to in four lines (throw → tap dice to lock before the timer runs out → only locked dice score → faster locks heat up the score), and PLAY. PLAY starts a fresh run.
- **End-of-run panel** on the throw screen when the run is won or lost: the result, the ante reached, the best throw score and total, and two buttons. NEW RUN calls `RunCoordinator.end_run()` then `start_run()` and reloads the throw screen; MENU returns to the start screen.
- **Run summary data:** `RunCoordinator` tracks the best single-throw score and antes cleared for the panel (presentation data only; no scoring change).
- The focus-loss cover and pause rules are unchanged on the new screens; the start screen has no timer, so it doesn't pause.

## Capabilities

### New Capabilities
- `run-flow`: start screen, how-to, end-of-run panel, new run / menu transitions, run summary.

### Modified Capabilities
- `ante-arc`: run end hands off to the end-of-run panel, and a new run starts from it. Rules for winning and losing are unchanged.

## Impact

- New start scene + script; `project.godot` main scene → start scene; `throw_scene.gd` shows the panel on `run_won`/`run_lost`; `run_coordinator.gd` gains the summary fields and a `new_run()` helper.
- Tests: new run resets arc, gold, inventory, bag and seed; the panel appears on win and on loss; MENU/NEW RUN transitions. Desktop playthrough adds a full lose → new run → play loop.

## Non-goals

- Meta progression, collection journal, saves (M2).
- Settings screen, Steady Mode toggle (M2 accessibility).
- Any scoring, Heat, timing or ante-target change.
- Styling beyond what `add-smoke-room-ui` provides (this change uses that theme once it lands; until then, default controls).
