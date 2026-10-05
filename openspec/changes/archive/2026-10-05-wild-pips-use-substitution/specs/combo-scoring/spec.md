## MODIFIED Requirements

### Requirement: Score formula
The score SHALL be `Score = (Pips + Bonus Chips + Charm Chips) × (Combo Mult + Charm Mult) × Heat`, where `Pips` is the sum of the pip values of all locked dice (the face adjusted by the die's material; a Wild die uses its substituted value, see the dice-materials and Wild requirements), `Bonus Chips` is the sum of `chips` across the combos in the chosen partition, `Charm Chips` is `ScoreBreakdown.charm_chips` accumulated by `on_score` hooks (default 0), `Combo Mult` is `max(base_mult, sum of mult across those combos)`, `Charm Mult` is `ScoreBreakdown.charm_mult` accumulated by `on_score` hooks (default 0.0), and `Heat` is supplied by the `heat` capability. The final score SHALL be floored to an integer. `ScoringEngine.score()` SHALL accept an optional `CharmInventory` parameter (default `null`); when provided, it calls each charm's `on_score(breakdown, ctx)` in slot order (0 → 4) before computing the final total.

#### Scenario: No charms — behaviour unchanged
- **WHEN** `ScoringEngine.score()` is called with no `CharmInventory` (or an empty one) on a Pair of 4s at Heat ×1.0
- **THEN** the score is `(8 + 10 + 0) × (1 + 0.0) × 1.0` = 18, identical to M0 behaviour

#### Scenario: Loose dice still contribute pips
- **WHEN** the locked set is 4,4,2 (a Pair plus one unmatched die) with Heat ×1.0
- **THEN** Pips is 10, Bonus Chips is 10, Combo Mult is 1, and the score is `(10 + 10) × 1 × 1.0` = 20

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

### Requirement: Wild carved dice use best-substitution combo detection
When one or more locked dice have `carve_type == &"wild"`, the engine SHALL try all possible face value substitutions (1–6) for each wild slot and choose the substitution that yields the highest-scoring partition. A Wild die SHALL score as its substituted value everywhere in the score: in combo detection, in the breakdown, and in `Pips` (with its material's `pip_offset` and `pip_multiplier` applied, floored at 0). Because pips depend on the substitution, candidates are compared on the full `(Pips + Bonus Chips) × Combo Mult` key, so among equal combos the higher-pip substitution wins. Charms keep reading printed faces (decision deferred, 2026-10-05).

The search is bounded at **N ≤ 2** wild dice in the M1 tray cap of 8, producing at most 6² = 36 candidate evaluations. The existing best-single-partition tie-break rules apply within each candidate.

#### Scenario: Wild die improves a Pair to a Triple
- **GIVEN** the locked set is [4, 4, Wild] where Wild's carved_face is anything (irrelevant to combo; Wild always substitutes)
- **WHEN** the throw is scored
- **THEN** the Wild die is treated as face 4, the combo resolves as a Triple, and the score reflects Triple chips and mult

#### Scenario: Wild die does not fire carve_activated
- **GIVEN** a Wild die that happens to show its carved face
- **WHEN** the die is locked
- **THEN** no bonus effect triggers at lock time (Wild only applies at scoring, not at lock signal)

#### Scenario: Wild pips use the substituted value
- **GIVEN** the locked set is [6, 6, Wild showing 1, 2, 2] at Heat ×1.0
- **WHEN** the throw is scored
- **THEN** the Wild is a 6, the combo is a Full House, Pips is 22, and the score is `(22 + 50) × 3` = 216

#### Scenario: Printed face no longer counts
- **GIVEN** the locked set is [4, 4, Wild showing 5, 1, 1, 6] at Heat ×1.0
- **WHEN** the throw is scored
- **THEN** the Wild is a 4 (Full House 4-4-4 + 1-1), Pips is 20, and the score is `(20 + 50) × 3` = 210

#### Scenario: Material applies to the substituted value
- **GIVEN** an Iron Wild completes three 6s
- **WHEN** the throw is scored
- **THEN** that die contributes `(6 + (−1)) × 1` = 5 pips

*(Note: `carve_activated` is emitted for Wild dice at lock time but the ThrowScene handler ignores `&"wild"`. The Gem and Spark bonus effects are handled in the score phase and ThrowScene respectively.)*
