## 1. Art

- [x] 1.1 `export_charm_icons()`: 12 medallions (archetype enamel, emblem per rule), import lossless + mipmaps, LFS, budget check

## 2. Data & scoring

- [x] 2.1 `CharmEffect.icon`; 12 `.tres` point at their icons
- [x] 2.2 `ScoreBreakdown.charm_triggers` from per-hook deltas in `ScoringEngine`

## 3. UI

- [x] 3.1 Slot icons (name on tap), shop card icons, shop owned row, end-panel build
- [x] 3.2 `ScoreCascade.charm_triggered` → slot pulse

## 4. Verification

- [x] 4.1 Tests: icons for all 12, triggers only for changed score, slots/shop/end panel show icons, pulse pops and settles
- [x] 4.2 GUT green; playthrough scenario (pulse iff fired) with screenshots; web build checked
