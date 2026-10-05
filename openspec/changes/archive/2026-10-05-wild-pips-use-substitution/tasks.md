## 1. Tests first (headless)

- [x] 1.1 [6, 6, Wild showing 1, 2, 2] → Full House, pips 22, score 216
- [x] 1.2 [4, 4, Wild showing 5, 1, 1, 6] → pips 20, score 210
- [x] 1.3 An Iron Wild as a 6 contributes 5 pips; a Glass Wild as a 6 contributes 12
- [x] 1.4 Regression: throws without a Wild score exactly as before; existing Wild tests stay green

## 2. Implementation

- [x] 2.1 `_pips_of()`; `score()` computes pips from the substituted dice (D1)
- [x] 2.2 `_best_wild_combos` evaluates per-candidate pips and returns them (D2)

## 3. Local verification

- [x] 3.1 Full GUT suite green
- [x] 3.2 Desktop playthrough: the Wild check also asserts pips use the substituted value; 0 failed checks
