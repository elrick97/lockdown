# Proposal: add-throw-loop

## Why

The throw — tumble, lock windows, re-rolls — is the signature mechanic and the thing M0's kill-gate exists to judge. Everything else in the game is scaffolding around this 10-second loop, so it must be playable (gray-box) before scoring, shops, or antes are worth building. This change covers the "Core throw loop" block of TASKS.md M0 except combo detection/scoring and the round loop, which follow as separate changes.

**Pillars served (PRD §2):** *Flow under pressure* (the lock window IS this pillar), *one thumb one screen* (tap-to-lock with forgiveness radius), and it instruments the board states needed to answer the Heat-dilemma hypothesis (PRD §3.2).

## What Changes

- **Dice bag model**: a run-owned bag of dice; a throw draws N (default 6, tray hard cap 8); drawn dice return to the bag at end of throw (discard/destroy rules deferred to the materials change).
- **Throw state machine**: `Draw → Tumble → Lock1 → Reroll → Lock2 → Reroll → Lock3 → ForceLock → Resolved`, with all die faces decided by the seeded RNG (`dice` stream) at the start of each tumble/re-roll — presentation strictly downstream.
- **Lock windows**: 3 windows with a delta-accumulated drain timer (duration a named tunable, default 2.5 s), tap-to-lock with nearest-unlocked-die snap forgiveness, force-lock of everything at the end of window 3. Window time remaining is recorded per window (the input Heat will consume in `add-scoring`).
- **Re-roll**: unlocked dice get new RNG-decided faces between windows.
- **Focus-loss handling**: on focus loss the game auto-pauses and obscures the tray; resume restores to the start of the interrupted window with a full timer, behind a 3-2-1 countdown.
- **Gray-box presentation only**: dice are tappable placeholder squares with numerals; the tumble is a brief placeholder animation. Real dice visuals arrive with the rendering-spike decision (PRD §10.1) — both spike options plug in beneath this state machine.

## Capabilities

### New Capabilities
- `dice-bag`: bag contents, draw rules, tray capacity.
- `throw-loop`: the throw state machine — tumble, lock windows, tap-to-lock, re-rolls, force-lock, per-window time tracking, and focus-loss/resume behavior.

### Modified Capabilities

_None. (`seeded-rng` is consumed, not changed.)_

## Impact

- New scenes/scripts under `/scenes` and `/scripts`; gameplay logic headless-testable (state machine and bag are plain classes, scene layer is presentation).
- Consumes `seeded-rng` (`dice` stream) and lives inside `project-structure` conventions.
- Unblocks `add-scoring` (needs locked sets + per-window times) and the playtest tuning tasks (window duration 2.0/2.5/3.0 s).

## Non-goals

- No scoring, combos, or Heat math (next change: `add-scoring`).
- No round/ante structure, targets, or win/lose (after that: `add-round-loop`).
- No dice materials, carved faces, charms, or shop.
- No real art, audio, or juice; no physics tumble — placeholder animation regardless of the pending spike decision.
- No Steady Mode yet (M2), but the timer code must not preclude an untimed mode.
