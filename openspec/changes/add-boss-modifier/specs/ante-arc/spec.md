## MODIFIED Requirements

### Requirement: AnteConfig carries round names and boss parameters
`AnteConfig` SHALL include:
- `round_names: Array[String]` — one label per ante (e.g. "Open", "Risk", "Boss"), parallel to `targets`
- `boss_antes: Array[int]` — 1-based ante indices that receive the boss modifier (default: `[3]`)
- `boss_window_scale: float` — multiplier applied to `lock_window_duration_s` on boss antes (current value: `0.5`)

#### Scenario: Round names accessible per ante
- **WHEN** `AnteConfig` is loaded with default values and `current_ante = 3`
- **THEN** `round_names[2]` returns `"Boss"`

#### Scenario: Boss antes list consulted
- **WHEN** `current_ante = 3` and `boss_antes = [3]`
- **THEN** the ante is identified as a boss ante and `boss_window_scale` is applied
