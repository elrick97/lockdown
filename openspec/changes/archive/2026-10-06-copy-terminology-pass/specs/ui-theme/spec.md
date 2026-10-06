## ADDED Requirements

### Requirement: Readable captions and progress copy
Text SHALL stay readable on a phone:
- Captions (plaque captions, YOUR BUILD / YOUR DICE, inspect tags) SHALL be at least 30 px, about 11 pt on a phone.
- TAP TO SKIP is 34 px.
- The HEAT value is 52 px.
- `UiStyle.MUTED` is #A8977C.

After each throw, the status band SHALL report progress:
- "<scored> scored · <to go> to go · <n> throws left";
- on the last throw, "LAST THROW · NEED <to go>";
- once the target is met, "Target hit!".

The Combos page SHALL define pips and CHIPS ("Pips are a die's face points. CHIPS = pips + combo and charm chips.").

#### Scenario: Last throw
- **WHEN** a throw leaves one throw and 90 points to go
- **THEN** the status reads "LAST THROW · NEED 90"
