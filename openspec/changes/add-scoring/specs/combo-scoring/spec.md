# Spec: combo-scoring

All base values below are named tunables on `ScoringConfig` (current values shown); the M0 playtest tunes them. `base_mult` = **1**.

| Combo | Match | `chips` | `mult` |
|---|---|---|---|
| Pair | 2 of a kind | 10 | 1 |
| Two Pair | two distinct pairs | 20 | 2 |
| Triple | 3 of a kind | 30 | 2 |
| Small Straight | 4-length run | 30 | 2 |
| Full House | a triple + a pair | 50 | 3 |
| Quad | 4 of a kind | 60 | 4 |
| Large Straight | 1-2-3-4-5-6 | 80 | 5 |
| Quint+ | 5+ of a kind | 100 | 8 |

## ADDED Requirements

### Requirement: Only locked dice score
Scoring SHALL consider only the locked dice of a resolved throw. Since the throw force-locks at the end of window 3, in practice all tray dice score, but the engine SHALL key off lock state, not tray membership.

#### Scenario: Loose die excluded
- **WHEN** a throw resolves with a die that was never locked
- **THEN** that die contributes neither pips nor combos to the score

### Requirement: Score formula
The score SHALL be `Score = (Pips + Bonus Chips) × (Combo Mult + Charm Mult) × Heat`, where `Pips` is the sum of face values of all locked dice, `Bonus Chips` is the sum of `chips` across the combos in the chosen partition, `Combo Mult` is `max(base_mult, sum of mult across those combos)`, `Charm Mult` is an injected input (**0** in M0), and `Heat` is supplied by the `heat` capability. The final score SHALL be floored to an integer.

#### Scenario: Single combo
- **WHEN** the locked set is a Pair of 4s (faces 4,4) with Heat ×1.0 and Charm Mult 0
- **THEN** the score is `(8 + 10) × (1) × 1.0` = 18

#### Scenario: Loose dice still contribute pips
- **WHEN** the locked set is 4,4,2 (a Pair plus one unmatched die) with Heat ×1.0
- **THEN** Pips is 10, Bonus Chips is 10, Combo Mult is 1, and the score is `(10 + 10) × 1 × 1.0` = 20

#### Scenario: Charm mult seam
- **WHEN** scoring is invoked with Charm Mult 2 on a Pair of 4s at Heat ×1.0
- **THEN** the score is `(8 + 10) × (1 + 2) × 1.0` = 54

### Requirement: Best-single-partition resolution
Each locked die SHALL belong to at most one combo. The engine SHALL evaluate the valid partitions of the locked set and choose the one yielding the highest `Score` (PRD §3.3). Dice in no combo are loose (pips only).

#### Scenario: Quad beats two pairs
- **WHEN** the locked set is 4,4,4,4
- **THEN** the chosen partition is a single Quad, not two Pairs or a Two Pair

#### Scenario: Full House beats Triple + Pair
- **WHEN** the locked set is 3,3,3,5,5
- **THEN** the chosen partition is a single Full House, not a Triple plus a Pair

#### Scenario: Large Straight beats Small Straight plus loose
- **WHEN** the locked set is 1,2,3,4,5,6
- **THEN** the chosen partition is a single Large Straight, not a Small Straight with two loose dice

#### Scenario: Quint beats Quad plus loose
- **WHEN** the locked set is 6,6,6,6,6
- **THEN** the chosen partition is a single Quint, not a Quad with one loose die

#### Scenario: Two genuine pairs partition as Two Pair
- **WHEN** the locked set is 2,2,5,5
- **THEN** the chosen partition is a single Two Pair combo (chips 20, mult 2), scoring higher than two separate Pairs

### Requirement: Deterministic tie-break
When two partitions yield an equal `Score`, the engine SHALL prefer the partition with fewer combos; if still tied, the partition whose highest-ranked combo outranks the other's (rank order: Quint > Large Straight > Quad > Full House > Small Straight > Triple > Two Pair > Pair). This guarantees a single, reproducible result.

#### Scenario: Equal-score partitions resolve identically
- **WHEN** two partitions of the same locked set produce identical scores
- **THEN** the engine returns the same partition every time, selected by the tie-break order
