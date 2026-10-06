# score-cascade Specification

## Purpose
Animated score reveal played after every throw resolution: the "jackpot payoff" loop. The breakdown builds up step by step on CHIPS × MULT × HEAT plaques (per-die pips, stamped combo with tiered shake and sparks, charm pulses, Heat), then the throw score ticks into the round total and target bar. Implemented in `ScoreCascade` (RefCounted, pure step list) and `ScoreHud`; tunables in `FeedbackConfig`.
## Requirements
### Requirement: Cascade plays after every throw resolution
After `ThrowController` emits `resolved`, the system SHALL play the score cascade before re-enabling THROW. The breakdown plays out on the **CHIPS**, **MULT** and **HEAT** plaques above the table as a sequence of steps built from the `ScoreBreakdown` (`ScoreCascade.build_steps`):
1. **Dice:** each scoring die, in index order, flashes gold and punches. Its pips (as scored, including material and Wild adjustments) float up from it as "+n" and are added to CHIPS.
2. **Stamp:** if any combo scored, the combo names slam onto the table as a tilted banner. The screen shakes and brass sparks burst, both scaled to the combo tier.
3. **Combos:** each combo adds its chips and mult, shown as floating numbers at the plaques. If no combo scored, MULT is raised to `base_mult`.
4. **Gem:** Gem carve chips are added, labelled GEM.
5. **Charms:** each entry in `charm_triggers` pulses its slot and adds its chips and mult deltas. Negative deltas show in red.
6. **Heat:** the HEAT plaque punches and its multiplier floats up.
7. **Throw score:** the throw score ticks from 0 to `final_score` and lands with a punch.
8. **Round total:** the score pours into the round total and the target progress bar.

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
- **THEN** the dice steps play, FULL HOUSE stamps in with a tier-3 shake and burst, CHIPS and MULT end on the breakdown's values, the throw score ticks up, the total pours in, and THROW enables only after the pour

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
Each scoring die SHALL flash gold (`Color(1.0, 0.82, 0.2)`) and punch to `lock_punch_scale` while its "+n" floats up, in index order, one `die_step_s` apart, before the stamp.

#### Scenario: All scoring dice highlighted
- **WHEN** the cascade begins with three scoring dice
- **THEN** die 0, then die 1, then die 2 flash, punch and float their pips, before the combo stamp

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

