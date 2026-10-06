## ADDED Requirements

### Requirement: Round rules are presented before play
Each ante's special rule SHALL be stated in plain words before its first throw, through the throw screen's ante intro card:
- Boss: the halved lock window, with its duration in seconds.
- Risk: the skip reward next to the win reward.

The rules themselves are unchanged.

#### Scenario: Rules come from the tunables
- **WHEN** `boss_window_scale` or `skip_reward_gold` changes
- **THEN** the intro card text changes with it
