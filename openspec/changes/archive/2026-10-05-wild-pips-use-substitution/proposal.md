## Why

A Wild die stands in for any value in combos, but its pips still come from its printed face. A Wild showing 1 that completes three 6s adds 1 pip, not 6, so the same Full House scores differently depending on a face the player never sees used. The owner ruled (2026-10-05) that a Wild's pips use its substituted value. The combo-scoring spec is silent on Wild pips today, so this is a rule change on a gameplay-critical system. PRD trace: §4.3 ("Wild (any value)").

**Pillars served:** *Readable depth*: a Wild that is "a 6" counts as a 6 everywhere in the score. *Jackpot payoff*: Wild-completed combos score their full value.

## What Changes

- **Pips for a Wild die use its substituted value**, with the die's material applied as usual: Iron −1, Glass ×2, floored at 0. Example: an Iron Wild standing in as a 6 adds 5 pips.
- **The substitution search picks the highest total score, pips included**, not just the best combos. Among equal combos it now prefers the substitution with more pips (e.g. the Wild becomes the 6 rather than the 1 in a Full House tie).
- The score breakdown shows the substituted value for the Wild, so the cascade and pips agree.

### Score impact (Heat ×1.0, current tunables)

| Locked dice | Today | After |
|---|---|---|
| [6, 6, Wild showing 1, 2, 2] → Full House (Wild = 6) | (17 + 50) × 3 = 201 | (22 + 50) × 3 = 216 |
| [4, 4, Wild showing 5, 1, 1, 6] → Full House (Wild = 4) | (21 + 50) × 3 = 213 | (20 + 50) × 3 = 210 (drops: the printed 5 out-pipped the 4 it stands for) |
| Throws without a Wild | unchanged | unchanged |

Both rows were computed by hand from the score formula; headless tests will assert them. No Heat or tunable changes; no balance sim exists yet (M2), so the headless tests carry the before/after numbers.

### Decision for you: charms and Wild faces

Charms read the locked faces through `CharmContext` (e.g. **Loaded**: "+6 chips per die showing 6", **Big Bucks**, **Precision**, **Collector**). After this change, should they also see a Wild as its substituted value?
- **Defer (recommended):** keep this change to pips as you specified; charms keep reading printed faces. Decide the charm rule separately once the 40-charm set (M2) shows how many charms it touches.
- **Include:** charms see substituted values too. That's more consistent, but it changes 4 of the 12 charms' outcomes and widens this change.

## Capabilities

### New Capabilities
- None.

### Modified Capabilities
- `combo-scoring`: the Wild requirement adds the pip rule and makes the search maximize total score; the score formula's `Pips` definition notes Wild substitution.

## Impact

- `scripts/scoring_engine.gd`: pips computed after the substitution is chosen; `_best_wild_combos` evaluates pips per candidate.
- `tests/test_carving.gd`: Wild pip cases (Bone, Iron, Glass Wild) and the tie preference.
- No change to Heat, tunables, charms (unless you choose "include"), or throws without a Wild.

## Non-goals

- Charm face rules (see decision above).
- Changing the N ≤ 2 Wild bound or Wild's lock-time behavior.
- Presentation beyond the breakdown showing the substituted value (the carved-face art comes with the first-pass art change).
