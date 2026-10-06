# run-flow Specification

## Purpose
The run lifecycle around the throw loop: start screen with how-to, end-of-run panel, new run / menu transitions and the run summary.
## Requirements
### Requirement: Start screen with how-to
The game SHALL open on a start screen showing a pictogram mark (no game name or logo until PRD Q4 is resolved), a how-to of at most four short lines covering throw, tap-to-lock before the timer empties, only locked dice score, and faster locks raise Heat, plus a PLAY button in the bottom thumb zone. PLAY SHALL start a fresh run (`RunCoordinator.new_run()`) and open the throw screen at ante 1.

#### Scenario: First launch
- **WHEN** the game starts
- **THEN** the start screen shows the mark, the how-to and PLAY, and no run timer is running

#### Scenario: Play
- **WHEN** the player presses PLAY
- **THEN** a fresh run starts (ante 1, 0 gold, empty charm and trinket slots, starting bag, new seed) and the throw screen opens

### Requirement: End-of-run panel
When the run is won or lost, the throw screen SHALL show an end-of-run panel with the result (run won / game over), the ante reached out of the total, the best single-throw score, and the final round total, plus NEW RUN and MENU buttons in the bottom thumb zone. NEW RUN SHALL start a fresh run and reload the throw screen; MENU SHALL return to the start screen. THROW stays disabled while the panel is shown.

#### Scenario: Game over
- **WHEN** the final throw of a round leaves the total below target
- **THEN** the panel reads game over with the ante reached, best throw and total, and NEW RUN and MENU are enabled

#### Scenario: Run won
- **WHEN** the final ante's target is met
- **THEN** the panel reads run won with the same summary

#### Scenario: New run from the panel
- **WHEN** the player presses NEW RUN
- **THEN** the run state is reset exactly as by PLAY and ante 1's throw screen opens

### Requirement: Run summary
`RunCoordinator` SHALL record the best single-throw final score of the current run (updated when each throw's cascade finishes) for the end-of-run panel. `new_run(seed = 0)` SHALL call `end_run()` then `start_run(seed)`, so the summary resets with the run. The summary is presentation data and SHALL NOT affect scoring.

#### Scenario: Best throw kept
- **WHEN** throws score 40, 120 and 90 in one run
- **THEN** the recorded best throw is 120, and it is 0 again after `new_run()`

