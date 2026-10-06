## ADDED Requirements

### Requirement: UI chrome is the rendered Smoke Room kit
Buttons, panels, readout plaques, charm sockets and the timer SHALL be drawn with the rendered UI kit (`res://assets/ui/`) as 9-patch textures, not flat colour boxes:
- **Primary buttons** (THROW, PLAY, CONTINUE): oxblood lacquer in a brass bezel.
- **Secondary buttons:** walnut in a brass bezel.
- **Panels:** stitched leather in a riveted brass frame.
- **Plaques** for readouts such as the round total and gold.
- **Sockets** for charm slots.
- **Timer:** a brass tube with an amber fill.

Each button has distinct normal, pressed and disabled art; hover brightens the normal art. Text on buttons has a dark outline, and text on labels a dark drop shadow, so it reads on lacquer, wood and felt. The `ui-theme` size and thumb-zone rules are unchanged.

#### Scenario: No flat boxes left
- **WHEN** any screen is shown
- **THEN** every button, panel, plaque, slot and the timer uses a texture from the UI kit

#### Scenario: Pressed and disabled read differently
- **WHEN** THROW is pressed, and later disabled during a throw
- **THEN** the pressed state shows the sunk, darker lacquer and the disabled state the dull, unlit lacquer
