# Design: add-scoring

## Context

`throw-loop` resolves to a `ThrowResult` (locked faces, lock order, per-window remaining times). This change consumes that and produces a score. It is the system M0's kill-gate hangs on, so two properties dominate: every feel number must be a tunable in one file, and the partition logic must be exhaustively testable headless.

## Goals / Non-Goals

**Goals:**
- Best-single-partition scoring that is correct on the named edge cases and deterministic on ties.
- The full `(Pips + Chips) × (ComboMult + CharmMult) × Heat` formula with charm seams that are 0 today and wired tomorrow.
- Heat curve and all combo values swappable via `.tres` for the dilemma-tuning sessions.

**Non-Goals:**
- Charms, bonus-chip sources, round targets, juice, Steady Mode UI (seam only).

## Decisions

**D1 — Partition by exhaustive evaluation over a capped set.**
The tray cap is 8 dice. The number of meaningful partitions of ≤8 dice into the eight combo types is small, and combos only form among same-face groups (pairs/triples/quads/quints) or consecutive runs (straights), so candidate generation is bounded and cheap. The engine enumerates candidate combos, then searches partitions for the max-scoring disjoint cover. No need for cleverness at this scale; clarity and testability win.
*Alternative:* greedy "take the best combo, recurse" — rejected; greedy fails cases like preferring a Full House over a locally-richer Quad-leaving Triple, and the whole point of D1 is provable correctness.

**D2 — `ScoringEngine` is a pure `RefCounted` taking `(ThrowResult, ScoringConfig, charm_mult, heat_mode)`.**
No globals, no scene, no RNG (scoring is deterministic given the resolved throw). Returns a `ScoreBreakdown` (partition, pips, chips, combo mult, heat, final). Headless GUT drives every edge case directly; the scene only renders the breakdown.

**D3 — `ScoringConfig` (`.tres`) holds every number.**
Combo `chips`/`mult` table, `base_mult`, `heat_min`/`heat_max`/`steady_heat`. The playtest tunes a file, not code — matching the data-driven law and the `ThrowConfig` precedent.

**D4 — Heat lives in its own tiny module, fed by `ScoringConfig`.**
Keeping `heat` a separate capability (not folded into `combo-scoring`) means the M0 dilemma tuning — which is *only* about the Heat curve — touches one isolated unit with its own tests, and the Steady Mode seam has a clear home.

**D5 — `ScoreBreakdown` carries the partition, not just the total.**
The gray-box readout (and later the juice cascade) needs to show *which dice made what*. Exposing the partition now means M1 juice renders from the same payload with no engine change.

## Risks / Trade-offs

- [Partition search cost grows with dice count] → bounded by the 8-die tray cap (D1); a perf test asserts a worst-case 8-of-a-kind board scores within budget, though that board is unreachable in M0.
- [Starting tunables are guesses] → accepted and expected; they exist to be tuned, and every one is a `.tres` field. The spec records current values, not final balance.
- [Float scores drift] → final score floored to int (spec'd); intermediate math in float is fine within one device because Heat itself is deterministic.

## Open Questions

- The exact Heat curve shape (linear vs. eased) is the M0 question itself — linear is the starting hypothesis, and the curve is a tunable so the playtest can answer it. Not a blocker.
