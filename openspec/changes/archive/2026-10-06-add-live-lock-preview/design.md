## Decisions

### D1: Preview reuses the engine, read-only
`ThrowController.snapshot_result()` (extracted from `_resolve`) builds the `ThrowResult` of the throw as it stands. The scene scores it with `inventory = null`, so no charms run, and shows `ScoreCascade.combo_base`. Nothing is mutated.

### D2: Balatro order in the cascade
`build_steps` puts the hand base first (stamp or base), then dice, Gem, charms and Heat. The stamp step carries the combo base deltas. Its float shows only the difference from what the plaques already display, so a preview that matches the final hand produces no redundant "+10 / +1" floats. A hand changed by window-3 force-locks floats its difference. The sums are unchanged, so the existing "steps sum to breakdown" tests still hold.

### D3: Status band
"Window n / 3 · COMBOS · c × m" fits one line at 48 px for the longest realistic case (two combos).
