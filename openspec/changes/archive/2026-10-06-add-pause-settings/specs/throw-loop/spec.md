## ADDED Requirements

### Requirement: Manual pause and pause menu
The throw screen SHALL show a pause button (the Blender pause chip, at least 126 px) in the bottom-left corner beside THROW. Pressing it pauses the game through the focus-loss pause, which freezes the tree and shows the cover, and opens the pause menu. The menu offers:
- Resume;
- How to play;
- Combos;
- Settings;
- Abandon run.

The menu card hugs its content and sits at the bottom of the screen, so every option is in thumb reach. While the menu is open, regaining app focus does not resume.

Resuming:
- **During a tumble, lock window or re-roll:** it runs the 3-2-1 countdown and restarts the window, as after focus loss.
- **Otherwise:** it resumes immediately.

The pause button is ignored while the end panel or cash-out panel shows. The focus-loss cover shows a "PAUSED" title.

#### Scenario: Pause mid-window
- **GIVEN** a lock window is open
- **WHEN** the player pauses and then resumes
- **THEN** the game stays frozen through a 3-2-1 countdown and the window restarts

#### Scenario: Pause when idle
- **WHEN** the player pauses before throwing and resumes
- **THEN** play resumes at once

#### Scenario: Focus returns while the menu is open
- **WHEN** the app regains focus with the pause menu open
- **THEN** the game stays paused until the player chooses Resume
