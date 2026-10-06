# run-flow Specification

## Purpose
The run lifecycle around the throw loop: start screen with how-to, end-of-run panel, new run / menu transitions and the run summary.
## Requirements
### Requirement: Start screen with how-to
The game SHALL open on a start screen showing:
- **Mark:** the rendered start hero (`res://assets/ui/start_hero.png`), with no game name or logo until PRD Q4 is resolved. It floats in a gentle idle bob (`HERO_BOB_PX` = 14 px, `HERO_BOB_S` = 3.2 s).
- **How-to:** at most four short lines covering throw, tap-to-lock before the timer runs out, only locked dice score, and faster locks raise Heat.
- **PLAY button:** in the bottom thumb zone, with a slow breathing scale pulse.

PLAY SHALL start a fresh run (`RunCoordinator.new_run()`) and open the throw screen at ante 1.

#### Scenario: First launch
- **WHEN** the game starts
- **THEN** the start screen shows the hero, the how-to and PLAY, and no run timer is running

#### Scenario: Play
- **WHEN** the player presses PLAY
- **THEN** a fresh run starts (ante 1, 0 gold, empty charm and trinket slots, starting bag, new seed) and the throw screen opens

### Requirement: End-of-run panel
When the run is won or lost, the throw screen SHALL show an end-of-run panel over a dimmer that covers everything on the throw screen; only the focus cover draws above it. THROW SHALL be hidden and disabled while the panel shows. The panel shows:
- **Result:** "RUN WON" (amber) or "GAME OVER" (cream), as a tilted stamp that slams in. A win shakes the screen at tier 4 and bursts sparks at tier 5; a loss shakes at tier 2 with no sparks. Tier values are from `FeedbackConfig`.
- **Final round total:** the headline. It counts up from 0 using the cascade's score-scaled tick and lands with a punch, with a caption giving the target.
- **Summary:** the ante reached out of the total, the best single-throw score, and the run seed.
- **Build:** the run's charm medallions under a "YOUR BUILD" caption.
- **Buttons:** NEW RUN (primary) and MENU, in the bottom thumb zone.

NEW RUN SHALL start a fresh run and reload the throw screen; MENU SHALL return to the start screen.

#### Scenario: Game over
- **WHEN** the final throw of a round leaves the total below target
- **THEN** the panel stamps GAME OVER, counts the final total up from 0 to the round total, lists the ante reached and best throw, and NEW RUN and MENU are enabled

#### Scenario: Run won
- **WHEN** the final ante's target is met
- **THEN** the panel stamps RUN WON with a shake and spark burst, and shows the same summary

#### Scenario: Nothing bright behind the panel
- **WHEN** the panel is shown
- **THEN** the tray, HUD, charm row and THROW are all drawn below the dimmer, and THROW is hidden

### Requirement: Run summary
`RunCoordinator` SHALL record the best single-throw final score of the current run (updated when each throw's cascade finishes) for the end-of-run panel. `new_run(seed = 0)` SHALL call `end_run()` then `start_run(seed)`, so the summary resets with the run. The summary is presentation data and SHALL NOT affect scoring.

#### Scenario: Best throw kept
- **WHEN** throws score 40, 120 and 90 in one run
- **THEN** the recorded best throw is 120, and it is 0 again after `new_run()`

