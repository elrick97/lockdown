# score-cascade Specification

## Purpose
Animated score reveal played after every throw resolution: the "jackpot payoff" loop. The breakdown builds up step by step on CHIPS × MULT × HEAT plaques (per-die pips, stamped combo with tiered shake and sparks, charm pulses, Heat), then the throw score ticks into the round total and target bar. Implemented in `ScoreCascade` (RefCounted, pure step list) and `ScoreHud`; tunables in `FeedbackConfig`.
## Requirements
### Requirement: Cascade plays after every throw resolution
After `ThrowController` emits `resolved`, the system SHALL play the score cascade before re-enabling THROW. The breakdown plays out on the **CHIPS**, **MULT** and **HEAT** plaques above the table as a sequence of steps built from the `ScoreBreakdown` (`ScoreCascade.build_steps`), in Balatro's order: hand base, then dice, then modifiers.
1. **Hand base:** if any combo scored, the combo names slam onto the table as a tilted banner. The screen shakes and brass sparks burst, both scaled to the combo tier. The plaques are set to the hand's base: combo chips, and combo mult floored at `base_mult`. Usually the live lock preview already shows these values, so only the difference floats up (for example, after window 3 force-locked more dice). With no combo, MULT is set to `base_mult` with no stamp.
2. **Dice:** each scoring die, in index order, flashes gold and punches. Its pips (as scored, including material and Wild adjustments) float up from it as "+n" and are added to CHIPS.
3. **Gem:** Gem carve chips are added, labelled GEM.
4. **Charms:** each entry in `charm_triggers` pulses its slot and adds its chips and mult deltas. Negative deltas show in red.
5. **Heat:** the HEAT plaque punches and its multiplier floats up.
6. **Throw score:** the throw score ticks from 0 to `final_score` and lands with a punch.
7. **Round total:** the score pours into the round total and the target progress bar.

The step values SHALL sum exactly to the breakdown:
- the sum of chips SHALL equal `pips + bonus_chips + charm_chips`;
- the sum of mult SHALL equal `combo_mult + charm_mult`;
- `floor(chips × mult × heat)` SHALL equal `final_score`.

THROW SHALL remain disabled for the whole sequence. The cascade is presentation only: no scoring, Heat or timing value changes.

#### Scenario: What you see is what you score
- **WHEN** any breakdown is turned into steps (loose dice, any combo, Glass, Iron, Gem, Wild, any charms including rewrites)
- **THEN** the steps' chips and mult sums reproduce the breakdown and its final score

#### Scenario: Full cascade on a scoring throw
- **WHEN** the controller emits `resolved` with a Full House
- **THEN** FULL HOUSE stamps in with a tier-3 shake and burst, the dice add their pips, CHIPS and MULT end on the breakdown's values, the throw score ticks up, the total pours in, and THROW enables only after the pour

#### Scenario: Cascade on a no-combo throw
- **WHEN** the controller emits `resolved` with only loose dice
- **THEN** there is no stamp and no shake, MULT shows `base_mult`, and the cascade completes normally

### Requirement: Cascade is skippable for headless contexts
The `ScoreCascade` object SHALL expose a `skip()` method. It immediately:
- kills the tween;
- sets the plaques, throw score, round total and target bar to their final values;
- removes floating numbers, sparks and the stamp;
- emits `finished` exactly once.

This keeps GUT tests and the balance sim from being blocked by animation timers.

#### Scenario: skip() resolves cascade instantly
- **WHEN** `ScoreCascade.skip()` is called at any point during the cascade
- **THEN** all readouts show their final values within the same frame, no transient effects remain, and `finished` fires once

### Requirement: Cascade duration is tunable
Cascade timing SHALL come from named tunables in `FeedbackConfig` (`res://resources/feedback_config.tres`), current values:

| Tunable | Value |
|---|---|
| `die_step_s` | 0.16 |
| `stamp_s` | 0.34 |
| `combo_step_s` | 0.32 |
| `charm_pulse_gap_s` | 0.18 |
| `heat_step_s` | 0.36 |
| `total_pour_s` | 0.45 |
| `target_hit_s` | 0.9 |

The throw-score tick scales with the score:

`cascade_duration_s × (tick_base + tick_per_decade × log10(score + 1))`

It is capped at `tick_max_s`. Current values: `cascade_duration_s` 0.8 (ScoringConfig), `tick_base` 0.5, `tick_per_decade` 0.25, `tick_max_s` 1.6.

#### Scenario: Bigger scores tick longer
- **WHEN** one throw scores 20 and another 2000
- **THEN** the 2000 tick lasts longer, and no tick exceeds `tick_max_s`

### Requirement: Die highlight reads as "this die scored"
Each scoring die SHALL flash gold (`Color(1.0, 0.82, 0.2)`) and punch to `lock_punch_scale` while its "+n" floats up. Dice go in index order, one `die_step_s` apart, *after* the hand's base step (the stamp, or the base step when there is no combo).

#### Scenario: All scoring dice highlighted
- **WHEN** the cascade begins with three scoring dice and a combo
- **THEN** the combo stamps first, then die 0, die 1 and die 2 each flash, punch and float their pips

### Requirement: Feedback scales with the combo tier
Combo tiers SHALL be:

| Tier | Combos |
|---|---|
| 0 | no combo |
| 1 | Pair, Two Pair |
| 2 | Triple, Small Straight |
| 3 | Full House |
| 4 | Quad, Large Straight |
| 5 | Quint |

A throw's tier is that of its best combo. The stamp's shake and spark burst come from per-tier tunables, current values:

| Tier | `shake_px_by_tier` | `shake_s_by_tier` | `sparks_by_tier` |
|---|---|---|---|
| 0 | 0 | 0 | 0 |
| 1 | 6 | 0.22 | 10 |
| 2 | 10 | 0.28 | 18 |
| 3 | 16 | 0.36 | 30 |
| 4 | 24 | 0.48 | 48 |
| 5 | 34 | 0.6 | 80 |

Each value SHALL strictly increase with tier.

#### Scenario: A quint hits harder than a pair
- **WHEN** a Quint and a Pair are scored
- **THEN** the Quint's shake amplitude, duration and spark count all exceed the Pair's

### Requirement: Target progress and TARGET HIT
A target progress bar SHALL sit in the HUD under the round total, filled to `total / target`. When a pour crosses the target, the cascade SHALL show a "TARGET HIT!" stamp with a burst and shake at `target_hit_tier` (current 3), and hold for `target_hit_s` before `finished`.

#### Scenario: Crossing the target
- **WHEN** a throw takes the round total from below the target to at or above it
- **THEN** `target_hit` fires and the flourish plays before the shop

### Requirement: Tap to skip the cascade
While the cascade plays, a tap on the throw screen that no button takes SHALL skip it. A tap within `skip_grace_s` (current 0.35 s) of the cascade starting SHALL be ignored. Skipping calls `skip()`, so every readout lands on its final value and THROW re-enables immediately. A muted "TAP TO SKIP" hint SHALL show while the cascade plays and hide when it finishes.

#### Scenario: Skip after the grace
- **GIVEN** a cascade has been playing for longer than `skip_grace_s`
- **WHEN** the player taps the table
- **THEN** the throw score shows its final value, THROW is enabled, and the hint hides

#### Scenario: Locking tap never skips
- **WHEN** the tap that locks the last die resolves the throw, and the player taps again within `skip_grace_s`
- **THEN** the cascade keeps playing

### Requirement: Floats and stamp never hide the numbers
Floating numbers SHALL stay readable:
- **Plaque floats** (chips, mult, Heat) spawn just above their plaque and rise `PLAQUE_RISE` (current 50 px), so they never cover a plaque value or the HUD panel.
- **Merging:** a delta that lands on a plaque whose float is still alive merges into it as one running number (for example "+30" then "+6" shows "+36"), with a re-punch.
- **Stacking:** other floats spawned at the same spot while one is still rising stack upward by `float_stack_px` (current 72 px).
- **Combo stamp:** after landing, it holds `stamp_hold_s` (current 0.55 s), then lifts away from the dice, shrinks and fades out.

#### Scenario: Charm chain on one plaque
- **WHEN** two charms add +30 and +6 chips in quick succession
- **THEN** one float above CHIPS reads "+36" instead of two overlapping floats

#### Scenario: Board readable after the stamp
- **WHEN** a combo stamps in and `stamp_hold_s` has passed
- **THEN** the stamp has lifted away and the dice are uncovered

