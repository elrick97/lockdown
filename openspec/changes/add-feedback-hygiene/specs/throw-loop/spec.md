## MODIFIED Requirements

### Requirement: Lock feedback
Each time a die is locked, `ThrowScene` SHALL:
- punch the die to `lock_punch_scale` (current 1.18) and back over `lock_punch_s` (0.18 s);
- nudge **only the dice tray** sideways by `lock_shake_px` (3 px) over `lock_shake_s` (0.1 s), returning exactly to its laid-out position;
- keep the existing haptic.

The scene root (HUD and labels) SHALL NOT move on a lock. Lock timing is unchanged.

#### Scenario: Lock punches
- **WHEN** a die is locked during a window
- **THEN** it scales up and settles back, the tray nudges, and the HUD stays still

### Requirement: Timer urgency
During the last `urgency_s` (current 0.8 s) of a lock window:
- the timer fill SHALL shift toward oxblood in proportion to how little time is left, and pulse at `urgency_pulse_hz` (current 2 Hz; never above 3 Hz);
- the frame pulses with it;
- the seconds left SHALL show as a number (one decimal) at the bar's end.

Outside that stretch, and outside windows, both show untinted and the number hides. Window timing is unchanged.

#### Scenario: Last stretch turns urgent
- **WHEN** 0.5 s remain in a window
- **THEN** the fill is tinted toward red and pulses at 2 Hz, "0.5" shows at the bar's end, and both return to normal when the window ends
