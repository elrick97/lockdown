## MODIFIED Requirements

### Requirement: M1 trinkets — Re-Tumble and Freeze Timer
The game SHALL ship two trinkets as `.tres` resources:
- **Re-Tumble** (cost: 3): activatable during any lock window; re-rolls all currently unlocked dice immediately.
- **Freeze Timer** (cost: 4): activatable during any lock window; extends the current window by up to 2 s, never beyond the window's full length (the same cap as Spark: `freeze_window(2.0)`).

#### Scenario: Re-Tumble re-rolls unlocked dice
- **GIVEN** Window 1 is active with 4 unlocked dice
- **WHEN** Re-Tumble is activated
- **THEN** the 4 unlocked dice receive new RNG faces and the tumble animation restarts

#### Scenario: Freeze Timer extends window
- **GIVEN** Window 1 has 0.5 s remaining
- **WHEN** Freeze Timer is activated
- **THEN** the window effectively has 2.5 s remaining

#### Scenario: Freeze Timer early in a window is capped
- **GIVEN** a 2.5 s lock window with 0.5 s elapsed (2.0 s remaining)
- **WHEN** Freeze Timer is activated
- **THEN** the window has 2.5 s remaining, not 4.0 s
