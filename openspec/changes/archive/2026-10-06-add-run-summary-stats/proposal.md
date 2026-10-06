## Why

UI/UX audit findings G1–G3:
- **G1:** losing shows the total, but not how close you were or what went well. Run summaries are what drives "one more run", the M0 gate metric.
- **G2:** the seed is shown but can't be used.
- **G3:** an empty build row on a loss shows five blank sockets, which looks like a bug.

A stale "GAME OVER." also sits behind the panel. PRD trace: §2 *Jackpot payoff*, *Collect & unlock*; run-flow end panel; seeded runs.

## What Changes

- **Result line under the final total:** "MISSED BY 93" (muted red) on a loss, or "BEAT BY 205" on a win.
- **Stats row:**
  - best combo seen this run (for example "Full House");
  - best throw;
  - rounds cleared;
  - gold earned this run.

  `RunCoordinator` records them as presentation data that scoring never reads.
- **Seed:** tap it to copy it to the clipboard, with a "Copied" float.
- **Empty build:** with no charms, the row reads "No charms this run" instead of five empty sockets.
- **Stale status:** the status line behind the panel is cleared when the panel shows.

## Capabilities

### Modified Capabilities
- `run-flow`: end-panel stats, copyable seed, empty-build copy.

## Impact

- `run_coordinator.gd` (best combo, rounds cleared, gold earned), and `throw_scene.gd` (end panel).
- No scoring change.
