## MODIFIED Requirements

### Requirement: Throw state machine
A throw SHALL progress `Draw → Tumble → Lock1 → Reroll → Lock2 → Reroll → Lock3 → ForceLock → Resolved`. On `Resolved` the throw SHALL expose the locked dice (faces and lock order) and the recorded per-window remaining times to downstream consumers (scoring). A die is **done** when it is locked or is a dead slot (a shattered Glass die, dice-materials spec); dead slots can never be locked, so they never hold a throw open.

#### Scenario: Full three-window throw
- **WHEN** a throw runs and at least one die remains unlocked through window 3
- **THEN** the states occur in the order above and `Resolved` reports all 3 window times

#### Scenario: Early resolution when everything is locked
- **WHEN** every tray die is done (locked or dead) during window N (N < 3), the last one by a lock
- **THEN** the throw transitions directly to `Resolved`, crediting the remaining time of window N and the full duration of windows N+1..3

#### Scenario: Early resolution with dead slots
- **GIVEN** one Glass die shattered at the end of window 1 and two live dice are left unlocked
- **WHEN** the player locks both live dice 0.5 s into window 2 (window 2.5 s)
- **THEN** the throw resolves at once with window times [0, 2.0, 2.5]

#### Scenario: Re-roll leaves nothing to lock
- **GIVEN** window N (N < 3) expires and, after the re-roll shatters the unlocked Glass dice, no live unlocked die remains
- **WHEN** the re-roll begins
- **THEN** the throw transitions directly to `Resolved` without running windows N+1..3, and those skipped windows are credited **0 s** remaining (no credit: nothing was locked in them)

### Requirement: Per-window time recording
For each window, the system SHALL record the remaining time at the moment the window ends (by expiry or by all dice becoming done). The three values are exposed on `Resolved` as the raw input for Heat. Windows skipped because the player locked everything early SHALL be credited at full duration; windows skipped because a re-roll left nothing to lock SHALL be credited 0 s.

#### Scenario: Times reported
- **WHEN** a throw resolves
- **THEN** three non-negative remaining-time values are available, one per window, with windows skipped by an early lock credited at full duration and windows skipped because nothing was left to lock credited 0 s

#### Scenario: No credit when nothing is left to lock
- **GIVEN** a tray of 1 Bone and 5 Glass dice, the Bone die locked in window 1 and the Glass dice left unlocked
- **WHEN** window 1 expires and the five Glass dice shatter
- **THEN** the throw resolves with window times [0, 0, 0] and Heat ×1.0, the same Heat as letting windows 2 and 3 run out
