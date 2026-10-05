# project-structure Specification

## Purpose
Project-level conventions: portrait display configuration, the canonical folder layout, and headless test execution.
## Requirements
### Requirement: Portrait display configuration
The Godot project SHALL render at a base resolution of 1080×2400 in portrait orientation, using `canvas_items` stretch mode with `expand` aspect, so UI scales across phone aspect ratios without letterboxing gameplay.

#### Scenario: Project boots in portrait
- **WHEN** the main scene is run in the editor or on device
- **THEN** the viewport is 1080×2400 portrait and the window does not allow landscape rotation

#### Scenario: Different aspect ratio device
- **WHEN** the project runs on a display taller or shorter than 20:9
- **THEN** canvas items scale uniformly and the safe area remains fully visible

### Requirement: Canonical folder layout
The repository SHALL contain the folders `/scenes`, `/scripts`, `/resources/charms`, `/resources/dice`, `/resources/faces`, `/resources/bosses`, `/assets`, and `/tools`. Gameplay content (charms, dice, faces, bosses) MUST live under `/resources` as `.tres` files; no content may be hardcoded in scripts.

#### Scenario: Content placement
- **WHEN** a future change adds a charm, die material, carved face, or boss modifier
- **THEN** it is added as a `.tres` file under the matching `/resources/<type>/` folder without editing engine scripts

### Requirement: Headless test execution
The project SHALL run its GUT test suite from the command line via the console binary with `--headless`, exiting non-zero on any test failure, so tests can gate CI and the future balance sim.

#### Scenario: CLI test run passes
- **WHEN** `godot_console --headless` is invoked with the GUT command-line runner and all tests pass
- **THEN** the process exits with code 0 and prints a test summary

#### Scenario: CLI test run fails
- **WHEN** any GUT test fails during a headless run
- **THEN** the process exits with a non-zero code

