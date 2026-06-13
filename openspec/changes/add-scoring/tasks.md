# Tasks: add-scoring

## 1. Config + data model

- [x] 1.1 `scripts/scoring_config.gd` (`ScoringConfig`, `Resource`): per-combo `chips`/`mult` table, `base_mult` 1, `heat_min` 1.0, `heat_max` 1.5, `steady_heat` 1.25; default `resources/scoring_config.tres`
- [x] 1.2 `scripts/score_breakdown.gd` (`ScoreBreakdown`, `RefCounted`): chosen partition (list of combos with their dice + chips + mult), loose dice, pips, bonus chips, combo mult, heat, final int score

## 2. Heat (headless)

- [x] 2.1 `scripts/heat.gd`: total_remaining -> multiplier per the curve, total_possible = 3 x lock_window_duration_s, clamp [0,1]; Steady (timers-disabled) mode returns `steady_heat`
- [x] 2.2 Heat tests: max speed -> `heat_max`, all-expired -> `heat_min`, midpoint -> x1.25, identical inputs -> identical Heat, Steady mode -> constant

## 3. Combo scoring (headless)

- [x] 3.1 Combo detection: enumerate candidate combos (same-face groups for pair/triple/quad/quint, consecutive runs for straights, triple+pair for full house, two distinct pairs for two pair) over the locked faces
- [x] 3.2 Best-single-partition search: max-scoring disjoint cover; loose dice score pips only; `base_mult` floor when no combos
- [x] 3.3 Deterministic tie-break (fewer combos, then highest-ranked combo by Quint>LargeStraight>Quad>FullHouse>SmallStraight>Triple>TwoPair>Pair)
- [x] 3.4 `ScoringEngine.score(result, config, charm_mult, heat_mode) -> ScoreBreakdown`: applies (Pips + Chips) x (ComboMult + CharmMult) x Heat, floored to int

## 4. Scoring tests (headless)

- [x] 4.1 Formula tests: single combo (Pair of 4s -> 18), loose-pips contribution (4,4,2 -> 20), charm-mult seam (charm_mult 2 -> 54)
- [x] 4.2 Partition edge cases: quad vs two pairs, full house vs triple+pair, large straight vs small straight + loose, quint vs quad + loose, genuine two-pair
- [x] 4.3 Tie-break determinism: an equal-score board returns the same partition across repeated calls
- [x] 4.4 Loose/locked: an unlocked die contributes nothing (build a `ThrowResult` with a non-force-locked die)

## 5. Scene integration (gray-box)

- [x] 5.1 On resolve, run `ScoringEngine` and show the breakdown: partition (which dice -> which combo), the formula line with real numbers, Heat bonus -- placeholder text, no juice
- [x] 5.2 Extend the in-tree scene smoke test: after a full throw, assert a non-zero score and a populated breakdown are displayed
- [~] 5.3 Verify on desktop: throw, lock a recognizable combo, confirm the readout math is right (game launched; human on-screen pass pending user)

## 6. Wrap up

- [x] 6.1 Full headless suite green via `tools/run_tests.ps1` (36 tests, 225 asserts)
- [x] 6.2 Update TASKS.md (tick combo-detection + scoring + Heat boxes with `add-scoring`)
- [x] 6.3 Commit
