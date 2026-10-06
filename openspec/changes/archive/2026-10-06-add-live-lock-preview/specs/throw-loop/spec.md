## ADDED Requirements

### Requirement: Live locked-set preview
During a lock window, after every lock, the throw screen SHALL show what the locked dice are worth so far. It scores the controller's read-only `snapshot_result()` with the scoring engine, without charms.
- **Status band:** "Window n / 3 · <COMBOS> · <chips> × <mult>", where chips and mult are the hand's base (`ScoreCascade.combo_base`: the sum of combo chips, and combo mult floored at `base_mult`). With dice locked but no combo, it reads "Window n / 3 · no combo yet". With nothing locked, it reads "Window n / 3 — TAP TO LOCK".
- **Plaques:** CHIPS and MULT show the same base values, and punch when they change. HEAT keeps its live value.

Charm effects, Gem chips, die pips and the final multiplied total are NOT previewed; the cascade reveals them. The preview never changes game state.

#### Scenario: Pair preview
- **WHEN** two 4s and a 2 are locked in Window 1
- **THEN** the status reads "Window 1 / 3 · PAIR · 10 × 1" and the plaques show CHIPS 10 and MULT 1

#### Scenario: Charms stay hidden
- **GIVEN** Hair Trigger is owned
- **WHEN** a pair is locked in Window 1
- **THEN** CHIPS shows the pair's 10, not the charm's bonus
