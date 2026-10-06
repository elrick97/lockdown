## MODIFIED Requirements

### Requirement: Die highlight reads as "this die scored"
Each scoring die SHALL flash gold (`Color(1.0, 0.82, 0.2)`) and punch to `lock_punch_scale` while its "+n" floats up. Dice go in index order, one `die_step_s` apart, *after* the hand's base step (the stamp, or the base step when there is no combo).

#### Scenario: All scoring dice highlighted
- **WHEN** the cascade begins with three scoring dice and a combo
- **THEN** the combo stamps first, then die 0, die 1 and die 2 each flash, punch and float their pips

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
