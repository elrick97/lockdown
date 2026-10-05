## MODIFIED Requirements

### Requirement: Spark extends current lock window
`ThrowScene` SHALL call `ThrowController.freeze_window(0.5)` when `carve_activated` emits with `carve_type == &"spark"`. `freeze_window(duration)` subtracts `duration` from the window's accumulated time, effectively adding that many seconds to the remaining window time, but never above the full window length: accumulated time is floored at 0, so the remaining time is capped at the window's duration (`lock_window_duration_s`, halved on a boss ante).

#### Scenario: Spark extends window by 0.5 s
- **GIVEN** a lock window with 0.8 s remaining (accumulated = window_s - 0.8)
- **WHEN** `freeze_window(0.5)` is called
- **THEN** the window now has 1.3 s remaining

#### Scenario: Spark early in a window is capped
- **GIVEN** a 2.5 s lock window with 0.2 s elapsed (2.3 s remaining)
- **WHEN** `freeze_window(0.5)` is called
- **THEN** the window has 2.5 s remaining, not 2.8 s
