## ADDED Requirements

### Requirement: Cascade plays after every throw resolution
After `ThrowController` emits `resolved`, the system SHALL play a score cascade animation sequence before re-enabling the THROW button. The sequence is: (1) locked-dice highlight, (2) combo label scale-in, (3) throw-score tick-up, (4) round-total tick-up. The THROW button SHALL remain disabled for the entire duration.

#### Scenario: Full cascade on a scoring throw
- **WHEN** the controller emits `resolved` with a non-zero score
- **THEN** locked dice flash gold for 0.15 s each in sequence, then the combo label scales from 0 to 1 over 0.2 s, then the throw score ticks from 0 to the final value over 0.8 s, then the round total ticks up over 0.3 s, and the THROW button becomes enabled only after the round total finishes

#### Scenario: Cascade on a zero-score throw
- **WHEN** the controller emits `resolved` and no dice are locked or score is 0
- **THEN** the combo label shows "No score" and ticks up from 0 to 0, the cascade still completes its full sequence (no crash/skip), and the THROW button re-enables normally

### Requirement: Cascade is skippable for headless contexts
The `ScoreCascade` object SHALL expose a `skip()` method that immediately kills the tween, sets all labels to their final values, and emits `finished`. This ensures GUT tests and the balance sim are not blocked by animation timers.

#### Scenario: skip() resolves cascade instantly
- **WHEN** `ScoreCascade.skip()` is called at any point during the cascade
- **THEN** all display labels reflect their final values within the same frame and the `finished` signal fires before the next frame

### Requirement: Cascade duration is tunable
The throw-score tick-up duration SHALL be exposed as a named tunable `cascade_duration_s` (default 0.8 s) in `ScoringConfig`. Changes to this value SHALL take effect on the next throw without requiring a scene reload.

#### Scenario: Shortened cascade via config
- **WHEN** `ScoringConfig.cascade_duration_s` is set to 0.2
- **THEN** the throw-score tick-up completes in approximately 0.2 s

### Requirement: Die highlight reads as "this die scored"
Each locked die SHALL briefly flash to a gold tint (`Color(1.0, 0.82, 0.2)`) for 0.15 s and return to the locked-green tint. Dice highlight sequentially in index order.

#### Scenario: All locked dice highlighted
- **WHEN** the cascade begins and three dice are locked
- **THEN** die 0 flashes gold then returns to green, then die 1, then die 2, before the combo label appears
