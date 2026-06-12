# Proposal: add-scoring

## Why

A throw currently resolves into raw data (faces, lock order, window times) with no payoff. Scoring turns it into the game: combos detected, numbers multiplied, and Heat converting speed into reward — the system M0's central hypothesis (PRD §3.2: does Heat create a real dilemma on mid-value boards?) exists to test. Covers the remaining "Core throw loop" scoring boxes in TASKS.md M0.

**Pillars served (PRD §2):** *Jackpot payoff* (the score cascade is the product) and *flow under pressure* (Heat is the mechanical link between speed and reward). *Readable depth* via dice combos everyone already knows.

## What Changes

- **Combo detection with best-single-partition** (settled rule, PRD §3.3): each locked die belongs to exactly one combo; the engine finds the highest-scoring partition of the locked set automatically. Combo set: Pair, Two Pair, Triple, Small Straight (4-run), Full House, Quad, Large Straight (6-run), Quint+. Unpartitioned dice score loose pips.
- **Score formula with the full seam**: `Score = (Pips + Bonus Chips) × (Combo Mult + Charm Mult) × Heat` — Bonus Chips and Charm Mult wired as inputs that are simply 0 in M0, so charms (M1) plug in without touching the engine.
- **Heat**: total remaining time across the three windows → multiplier via a tunable curve (base ×1.0 up to ×1.5 at full speed, exposed as named tunables for the M0 dilemma-tuning sessions).
- **Combo base values as a data resource** (`ScoringConfig` `.tres`): pips-bonus and mult per combo, the Heat curve parameters — every number the playtest will want to poke lives in one file.
- **Gray-box score display**: on resolve, the throw scene shows the partition breakdown (which dice formed what), the formula line with real numbers, and the Heat bonus — placeholder text, no juice yet (juice is an M1 milestone).
- All scoring logic headless (plain `RefCounted`, consumes `ThrowResult`), with GUT tests for the partition edge cases named in TASKS.md: quad vs. two pairs, full house vs. triple+pair, straights overlapping sets.

## Capabilities

### New Capabilities
- `combo-scoring`: combo definitions, best-single-partition resolution, and the score formula with its charm-ready seams.
- `heat`: the time-remaining → multiplier conversion and its tunable curve.

### Modified Capabilities

_None. (`throw-loop` already exposes the resolve payload this consumes.)_

## Impact

- New scripts + `ScoringConfig` resource; throw scene extended with the score readout.
- Consumes `ThrowResult` (faces, window times) — no changes to the throw loop.
- Unblocks `add-round-loop` (targets need scores) and the M0 Heat-dilemma playtest protocol.

## Non-goals

- No Bonus Chips sources, no charms, no carved faces — the formula accepts them; nothing produces them yet.
- No round targets or win/lose (next change).
- No score juice (tick-up audio, cascade animation) — M1, by design (PRD §5 budgets it as its own milestone).
- No Steady Mode Heat handling yet (M2), but the curve must expose the fixed-value seam (population-average constant) it will need.
