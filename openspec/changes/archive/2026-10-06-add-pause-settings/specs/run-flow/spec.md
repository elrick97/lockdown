## ADDED Requirements

### Requirement: Abandon run
The pause menu's Abandon run SHALL ask for confirmation ("The run ends now and counts as a loss"). Confirming unpauses, skips any running cascade, and ends the run as a loss through the end-of-run panel. The throw loop never ticks behind the end panel.

#### Scenario: Abandon
- **WHEN** the player confirms Abandon run
- **THEN** the end panel shows GAME OVER and the run is over
