## MODIFIED Requirements

### Requirement: THROW button re-enable timing
The THROW button SHALL remain disabled from the moment a throw begins until the score cascade animation fully completes. It SHALL NOT re-enable at the moment the score is computed.

#### Scenario: Button disabled during cascade
- **WHEN** `ThrowController` emits `resolved`
- **THEN** the THROW button remains disabled while `ScoreCascade` is running and becomes enabled only after `ScoreCascade` emits `finished`

#### Scenario: Button disabled when round is complete
- **WHEN** the cascade completes and `RoundState` is done (round won or lost)
- **THEN** the THROW button remains disabled (the round-won/lost state takes precedence)
