## ADDED Requirements

### Requirement: Live Heat readout during windows
While a lock window is open, the HEAT plaque SHALL show the Heat the throw would get if every unlocked die were locked now. That is `Heat.from_remaining(ThrowController.projected_window_remaining(), …)`, where:
- past windows keep their recorded remaining time;
- the current window uses its time left;
- later windows count as full, matching what locking everything records.

The readout drops as time drains. It is display only: the Heat formula and scoring are unchanged. At resolution, the cascade shows the breakdown's actual Heat.

#### Scenario: Readout tracks the clock
- **GIVEN** a 2.5 s window with 0.5 s elapsed in Window 1
- **WHEN** the HUD updates
- **THEN** HEAT shows `from_remaining([2.0, 2.5, 2.5])`
