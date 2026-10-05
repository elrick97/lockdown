## MODIFIED Requirements

### Requirement: Boss round halves lock-window duration
On a boss ante, `ThrowScene` SHALL apply `boss_window_scale` to the lock-window duration before constructing the `ThrowController`. The effective window duration for scoring Heat SHALL match the boss-scaled value.

#### Scenario: Boss ante has shorter windows
- **GIVEN** `lock_window_duration_s = 2.5` and `boss_window_scale = 0.5`
- **WHEN** the player enters ante 3 (a boss ante)
- **THEN** each lock window drains in 1.25 s instead of 2.5 s

#### Scenario: Non-boss ante is unaffected
- **WHEN** the player is on ante 1 or 2
- **THEN** lock windows run at the full `lock_window_duration_s`

### Requirement: Round type label shown in UI
`ThrowScene` SHALL display the current ante's round type name (from `AnteConfig.round_names`) in the ante label.

#### Scenario: Boss label visible
- **WHEN** the player enters ante 3
- **THEN** the ante label reads `"ANTE 3 / 3 — BOSS ROUND"`
