## Context

`ScoringEngine.score()` computes `pips` from the printed faces before scoring. For Wilds it then calls `_best_wild_combos`, which tries every substitution with that same fixed `pips`. `_eval` ranks partitions by `(pips + chips) × combo_mult`, then fewer combos, then higher top combo. Since the 2026-10-05 freeze fix, `_best_wild_combos` returns `[chosen, substituted_locked]` and the breakdown assigns dice from the substituted faces.

## Goals / Non-Goals

**Goals:** Wild pips use the substituted value; the substitution is chosen on the full score; breakdown, pips and score agree.

**Non-goals:** charms keep reading printed faces (deferred); no Heat or tunable change.

## Decisions

### D1: One pip function over the dice as scored
Extract `_pips_of(dice: Array, result: ThrowResult) -> int`: the sum of `maxi(0, face + offset) × mult` per die, reading `pip_offsets`/`pip_multipliers` by each die's `idx`. `score()` calls it on `combo_locked` (the substituted dice) once the partition is chosen, so the formula needs no Wild special case.

### D2: The search feeds each candidate its own pips
In `_best_wild_combos`, compute `_pips_of(mod_locked, result)` per substitution and pass it to `_search` and `_eval`. The existing key `(pips + chips) × combo_mult` then maximizes the total score, and the existing tie-break order still applies. It returns `[chosen, substituted_locked, pips]`. *Alternative:* choose combos first, with pips as a secondary key. Rejected because it can pick weaker total scores, contradicting "highest-scoring".

### D3: Charms unchanged
`CharmContext.from_result` keeps reading `result.faces` (printed), recorded in the spec as a deferred decision.

## Risks / Trade-offs

- **Some Wild throws score lower** (213 → 210 in the proposal's example) when the printed face out-pipped the substitute. This is what the rule asks for.
- **No balance sim yet** → the proposal's hand-computed cases become headless tests.
