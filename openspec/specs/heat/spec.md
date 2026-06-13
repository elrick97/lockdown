# Spec: heat

Named tunables on `ScoringConfig` (current values): `heat_min` = **1.0**, `heat_max` = **1.5**, `steady_heat` = **1.25** (population-average placeholder for Steady Mode).

## Requirements

### Requirement: Heat from total remaining time
Heat SHALL be computed from the total remaining time across the three lock windows (the `window_remaining_s` array on the resolved throw). Let `total_possible = 3 × lock_window_duration_s`. Then `Heat = heat_min + (heat_max − heat_min) × clamp(total_remaining / total_possible, 0, 1)`. Locking everything in window 1 credits all three windows at full duration and yields `heat_max`; letting every window expire yields `heat_min`.

#### Scenario: Maximum speed
- **WHEN** a throw resolves with all three windows credited at full duration (everything locked instantly in window 1)
- **THEN** Heat equals `heat_max` (×1.5)

#### Scenario: Slowest play
- **WHEN** a throw resolves with zero remaining time across all windows
- **THEN** Heat equals `heat_min` (×1.0)

#### Scenario: Midpoint
- **WHEN** the total remaining time is exactly half of `total_possible`
- **THEN** Heat equals `heat_min + (heat_max − heat_min) × 0.5` (×1.25)

### Requirement: Heat is frame-rate and device independent
Because Heat derives only from the recorded `window_remaining_s` values (themselves accumulated from `delta`), the same seed and same lock timings SHALL produce the same Heat on any device or frame rate.

#### Scenario: Identical inputs, identical Heat
- **WHEN** two resolved throws carry identical `window_remaining_s` arrays
- **THEN** they yield identical Heat values

### Requirement: Steady Mode fixed Heat seam
The Heat computation SHALL accept a "timers disabled" mode that returns the constant `steady_heat` regardless of recorded window times, so accessibility players face the same ante curve with equal expected scoring (PRD §4.6). M0 does not expose this mode in the UI, but the seam SHALL exist.

#### Scenario: Steady Mode returns the constant
- **WHEN** Heat is computed in Steady (timers-disabled) mode
- **THEN** the result is `steady_heat` (×1.25), independent of the window times
