## ADDED Requirements

### Requirement: Transition wipe uses the Smoke Room fog
The screen-transition wipe SHALL be dark warm smoke (`smoke_color` #120B08) dissolving along the same seamless fog noise texture as the overlay. It is drawn above the overlay and every screen (canvas layer 100), as one canvas pass with two noise samples.

#### Scenario: Shared noise
- **WHEN** a transition plays
- **THEN** its material samples `SmokeOverlay.noise_texture()`
