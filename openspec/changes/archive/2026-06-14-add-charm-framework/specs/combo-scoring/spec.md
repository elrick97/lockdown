## MODIFIED Requirements

### Requirement: Score formula
The score SHALL be `Score = (Pips + Bonus Chips + Charm Chips) × (Combo Mult + Charm Mult) × Heat`, where `Pips` is the sum of face values of all locked dice, `Bonus Chips` is the sum of `chips` across the combos in the chosen partition, `Charm Chips` is `ScoreBreakdown.charm_chips` accumulated by `on_score` hooks (default 0), `Combo Mult` is `max(base_mult, sum of mult across those combos)`, `Charm Mult` is `ScoreBreakdown.charm_mult` accumulated by `on_score` hooks (default 0.0), and `Heat` is supplied by the `heat` capability. The final score SHALL be floored to an integer. `ScoringEngine.score()` SHALL accept an optional `CharmInventory` parameter (default `null`); when provided, it calls each charm's `on_score(breakdown, ctx)` in slot order (0 → 4) before computing the final total.

#### Scenario: No charms — behaviour unchanged
- **WHEN** `ScoringEngine.score()` is called with no `CharmInventory` (or an empty one) on a Pair of 4s at Heat ×1.0
- **THEN** the score is `(8 + 10 + 0) × (1 + 0.0) × 1.0` = 18, identical to M0 behaviour

#### Scenario: Charm adds chips
- **WHEN** a charm's `on_score` sets `breakdown.charm_chips += 20` and the locked set is a Pair of 4s at Heat ×1.0
- **THEN** the score is `(8 + 10 + 20) × 1 × 1.0` = 38

#### Scenario: Charm adds mult
- **WHEN** a charm's `on_score` sets `breakdown.charm_mult += 2.0` and the locked set is a Pair of 4s at Heat ×1.0
- **THEN** the score is `(8 + 10) × (1 + 2.0) × 1.0` = 54

#### Scenario: Multiple charms stack additively
- **WHEN** two charms each add `charm_mult += 1.0` and the locked set is a Pair of 4s at Heat ×1.0
- **THEN** the score is `(8 + 10) × (1 + 2.0) × 1.0` = 54 (both charm_mult contributions summed)

#### Scenario: Hooks fire in slot order
- **WHEN** two charms are in slots 0 and 1, and charm 1's hook reads `breakdown.charm_chips` written by charm 0
- **THEN** charm 1 sees the value charm 0 wrote (slot 0 fires before slot 1)
