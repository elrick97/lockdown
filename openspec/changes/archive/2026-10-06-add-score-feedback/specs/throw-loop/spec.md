## MODIFIED Requirements

### Requirement: Screen shake on combo land
When a scored throw contains at least one combo, `ThrowScene` SHALL shake when the combo stamp lands. The shake is a decaying oscillation on the scene root's `position.x` in 6 alternating steps, with amplitude and duration from the combo tier (`FeedbackConfig.shake_px_by_tier` and `shake_s_by_tier`; see the score-cascade spec). The shake is a Tween on the scene root `position`. It resolves back to `Vector2.ZERO`, and a new shake replaces one in progress. It does not conflict with `_apply_layout()` because anchors define the Control rect independently of `position`.

#### Scenario: Combo lands → shake
- **GIVEN** a throw resolves with a Pair or better
- **WHEN** the cascade's combo stamp lands
- **THEN** the scene root shakes by its tier's amplitude, which decays to zero within its tier's duration

#### Scenario: No combo → no shake
- **GIVEN** a throw resolves with all loose dice (no combo)
- **WHEN** the cascade plays
- **THEN** no shake is requested

## ADDED Requirements

### Requirement: Lock feedback
Each time a die is locked, `ThrowScene` SHALL:
- punch the die to `lock_punch_scale` (current 1.18) and back over `lock_punch_s` (0.18 s);
- play a small shake of `lock_shake_px` (3 px) over `lock_shake_s` (0.1 s);
- keep the existing haptic.

Lock timing is unchanged.

#### Scenario: Lock punches
- **WHEN** a die is locked during a window
- **THEN** it scales up and settles back, and the table nudges

### Requirement: Timer urgency
During the last `urgency_s` (current 0.8 s) of a lock window, the timer fill SHALL shift toward oxblood in proportion to how little time is left, and pulse. The frame pulses with it. Outside that stretch, and outside windows, both show untinted. Window timing is unchanged.

#### Scenario: Last stretch turns urgent
- **WHEN** less than `urgency_s` remains in a window
- **THEN** the fill is tinted toward red, and returns to untinted when the window ends
