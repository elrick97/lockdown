## Why

The throw loop is complete but a throw goes nowhere — there is no target to beat, no win/lose state, and no sense of progression. The M0 gate playtest requires an actual *run* with stakes, not isolated throws. This change adds the minimal round and ante structure needed to make a session feel like a game.

**Design pillars served:** Flow under pressure (target score creates do-or-die stakes on every throw); Jackpot payoff (clearing an ante target is the first jackpot moment); Readable depth (the 3-throw budget is immediately legible as a resource).

## What Changes

- **RoundState**: tracks current throw number (1–3), cumulative score for the round, and the target. Emits win/lose at the end of throw 3 or when target is reached early.
- **AnteArc**: a 3-ante progression with hardcoded target values and a win/lose outcome for the run. Starting a new ante resets the round.
- **Scene wiring**: the gray-box throw scene drives `RoundState` and `AnteArc`, showing ante number, throw budget, running total, and target on screen. Displays WIN/LOSE at run end.

## Capabilities

### New Capabilities
- `round-loop`: target score, 3-throw budget, cumulative running total, and win/lose state for a single round
- `ante-arc`: 3-ante progression with hardcoded targets and run-end win/lose outcome

### Modified Capabilities
*(none — throw-loop, combo-scoring, and heat behavior are unchanged)*

## Impact

- New scripts: `scripts/round_state.gd`, `scripts/ante_arc.gd`
- New resources: `resources/ante_arc.tres` (hardcoded ante targets)
- `scenes/throw/throw_scene.gd`: wired to `RoundState` and `AnteArc`; UI labels updated
- New GUT tests covering round win/loss transitions, ante progression, and run end
- No changes to scoring engine, throw controller, or RNG service

## Non-goals

- Shop, gold economy, charm framework (M1)
- Animated score tick-up or combo screen shake (M1)
- Difficulty scaling past 3 hardcoded antes (M2 full ante curve)
- Save/resume mid-run (M2)
- Any UI polish beyond gray-box text labels
