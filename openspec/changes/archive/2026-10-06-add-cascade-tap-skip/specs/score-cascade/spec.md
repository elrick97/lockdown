## ADDED Requirements

### Requirement: Tap to skip the cascade
While the cascade plays, a tap on the throw screen that no button takes SHALL skip it. A tap within `skip_grace_s` (current 0.35 s) of the cascade starting SHALL be ignored. Skipping calls `skip()`, so every readout lands on its final value and THROW re-enables immediately. A muted "TAP TO SKIP" hint SHALL show while the cascade plays and hide when it finishes.

#### Scenario: Skip after the grace
- **GIVEN** a cascade has been playing for longer than `skip_grace_s`
- **WHEN** the player taps the table
- **THEN** the throw score shows its final value, THROW is enabled, and the hint hides

#### Scenario: Locking tap never skips
- **WHEN** the tap that locks the last die resolves the throw, and the player taps again within `skip_grace_s`
- **THEN** the cascade keeps playing
