## 1. Data

- [x] 1.1 `ScoreBreakdown.die_pips` / `gem_chips` from the engine (presentation only)
- [x] 1.2 `FeedbackConfig` + `feedback_config.tres` (timings, tiers, lock/urgency tunables)

## 2. Cascade & HUD

- [x] 2.1 `ScoreCascade.build_steps` / `sum_steps`; tween plays steps; skip clears transients, emits once
- [x] 2.2 `ScoreHud`: CHIPS × MULT × HEAT plaques, floats, stamp, spark burst, target bar
- [x] 2.3 Tiered shake + burst on stamp; TARGET HIT flourish; score-scaled tick with landing punch

## 3. Throw loop

- [x] 3.1 Lock punch + nudge; timer urgency tint/pulse; live Heat readout (`projected_window_remaining`)
- [x] 3.2 Status band cleared while the score builds

## 4. Verification

- [x] 4.1 Tests: steps sum to breakdown across hands/charms/materials; tiers rise; tick scales; no combo → no shake; skip; live Heat; urgency; THROW waits
- [x] 4.2 GUT green; playthrough (stamp, shake, CHIPS build-up, landing) with screenshots; web build checked
