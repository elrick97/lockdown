## MODIFIED Requirements

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
