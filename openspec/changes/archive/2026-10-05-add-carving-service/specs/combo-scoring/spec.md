## ADDED Requirements

### Requirement: Gem carved dice add bonus chips on lock
When a locked die shows its `carved_face` and its `carve_type == &"gem"`, the scoring engine SHALL add **20 chips** to `ScoreBreakdown.charm_chips` (named tunable: `gem_chips`, current value: **20**). This applies per qualifying die; multiple Gem dice stack.

#### Scenario: Gem die locked on carved face
- **GIVEN** a die with `carved_face = 5`, `carve_type = &"gem"` is drawn and locked showing face 5
- **WHEN** the throw is scored
- **THEN** `breakdown.charm_chips` is increased by 20

#### Scenario: Gem die locked on non-carved face
- **GIVEN** the same Gem die is locked showing face 3 (not its carved face 5)
- **WHEN** the throw is scored
- **THEN** no bonus chips are added for that die

### Requirement: Wild carved dice use best-substitution combo detection
When one or more locked dice have `carve_type == &"wild"`, the engine SHALL try all possible face value substitutions (1–6) for each wild slot and choose the substitution that yields the highest-scoring partition.

The search is bounded at **N ≤ 2** wild dice in the M1 tray cap of 8, producing at most 6² = 36 candidate evaluations. The existing best-single-partition tie-break rules apply within each candidate.

#### Scenario: Wild die improves a Pair to a Triple
- **GIVEN** the locked set is [4, 4, Wild] where Wild's carved_face is anything (irrelevant to combo; Wild always substitutes)
- **WHEN** the throw is scored
- **THEN** the Wild die is treated as face 4, the combo resolves as a Triple, and the score reflects Triple chips and mult

#### Scenario: Wild die does not fire carve_activated
- **GIVEN** a Wild die that happens to show its carved face
- **WHEN** the die is locked
- **THEN** no bonus effect triggers at lock time (Wild only applies at scoring, not at lock signal)

*(Note: `carve_activated` is emitted for Wild dice at lock time but the ThrowScene handler ignores `&"wild"`. The Gem and Spark bonus effects are handled in the score phase and ThrowScene respectively.)*
