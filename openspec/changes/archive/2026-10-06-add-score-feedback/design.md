## Context

The old cascade flashed dice, popped a combo label and ticked one number, with one fixed 8 px shake. The breakdown already carried everything needed, except per-die pips and gem chips, which are now recorded as presentation fields.

## Decisions

### D1: Steps are a pure function of the breakdown
`ScoreCascade.build_steps(bd, base_mult)` returns the display steps (`die`, `stamp`, `combo`, `base`, `gem`, `charm`, `heat`) with chips and mult deltas. `sum_steps` lets tests prove the display equals the score for every hand shape. The tween just plays the steps.

### D2: Presentation fields on ScoreBreakdown
The engine fills these alongside the score, and scoring never reads them:
- `die_pips`: per die, from the same `_die_pip` used for scoring.
- `gem_chips`: carve chips.
- `charm_triggers`: from add-charm-icons.

### D3: ScoreHud owns the visuals
A full-rect, input-transparent Control owns:
- the CHIPS / MULT / HEAT plaques (kit plaques);
- the target bar (the timer kit drawn at half scale, so its 9-patch margins fit a thin bar);
- floating labels;
- the stamp label;
- CPU spark bursts with a generated radial texture (no asset, Compatibility-safe).

It sits above the table and below the end panel and focus cover.

### D4: Signals for scene-owned effects
The cascade emits `shake_requested(px, s)`, `charm_triggered(slot)` and `target_hit`. The scene owns the shake tween, killing the previous one so a lock nudge and a stamp never fight.

### D5: Tunables in FeedbackConfig
A separate resource keeps presentation tuning out of `ScoringConfig`. `cascade_duration_s` stays in ScoringConfig as the tick's base.

### D6: Live Heat
`ThrowController.projected_window_remaining()` is a read-only copy of the window record, with the current window's time left and later windows full. `_end_window_all_locked` records exactly this, so the readout is honest: it is the Heat you get by locking everything now.

## Risks / Trade-offs

- **Cascade length:** about 2–4 s for big hands. THROW waits for it. It stays skippable in code; a tap-to-skip input is left to playtesting (M2 settings).
- **Desktop playthrough timing:** checks are now frame-independent windows of up to 6 s.
