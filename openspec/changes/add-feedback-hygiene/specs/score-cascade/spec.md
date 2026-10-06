## ADDED Requirements

### Requirement: Floats and stamp never hide the numbers
Floating numbers SHALL stay readable:
- **Plaque floats** (chips, mult, Heat) spawn just above their plaque and rise `PLAQUE_RISE` (current 50 px), so they never cover a plaque value or the HUD panel.
- **Merging:** a delta that lands on a plaque whose float is still alive merges into it as one running number (for example "+30" then "+6" shows "+36"), with a re-punch.
- **Stacking:** other floats spawned at the same spot while one is still rising stack upward by `float_stack_px` (current 72 px).
- **Combo stamp:** after landing, it holds `stamp_hold_s` (current 0.55 s), then lifts away from the dice, shrinks and fades out.

#### Scenario: Charm chain on one plaque
- **WHEN** two charms add +30 and +6 chips in quick succession
- **THEN** one float above CHIPS reads "+36" instead of two overlapping floats

#### Scenario: Board readable after the stamp
- **WHEN** a combo stamps in and `stamp_hold_s` has passed
- **THEN** the stamp has lifted away and the dice are uncovered
