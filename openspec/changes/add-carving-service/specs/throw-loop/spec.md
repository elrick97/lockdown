## MODIFIED Requirements

### Requirement: Carved dice emit carve_activated on lock
`ThrowController` SHALL emit `signal carve_activated(die_index: int, carve_type: StringName)` when:
1. A die is locked (by player tap or force-lock), AND
2. The die has a non-empty `carve_type`, AND
3. The die's current face equals its `carved_face`

The signal fires after `die_locked` and before charm hooks.

#### Scenario: Spark die locked on carved face
- **GIVEN** a die with `carved_face = 4`, `carve_type = &"spark"` is drawn and locked showing face 4
- **WHEN** the die is locked
- **THEN** `carve_activated` emits with `carve_type = &"spark"`

#### Scenario: Carved die locked on wrong face
- **GIVEN** a die with `carved_face = 4`, `carve_type = &"spark"` is locked showing face 2
- **WHEN** the die is locked
- **THEN** `carve_activated` does NOT emit

### Requirement: Spark extends current lock window
`ThrowScene` SHALL call `ThrowController.freeze_window(0.5)` when `carve_activated` emits with `carve_type == &"spark"`. `freeze_window(duration)` subtracts `duration` from the window's accumulated time, effectively adding that many seconds to the remaining window time.

#### Scenario: Spark extends window by 0.5 s
- **GIVEN** a lock window with 0.8 s remaining (accumulated = window_s - 0.8)
- **WHEN** `freeze_window(0.5)` is called
- **THEN** the window now has 1.3 s remaining

### Requirement: ThrowResult carries carve_types parallel array
`ThrowResult.carve_types: Array[StringName]` SHALL hold the carve_type that activated for each tray die, or `&""` if no carve activated. Length equals the number of drawn dice.
