## ADDED Requirements

### Requirement: First-time tips
The game SHALL show a one-line coach mark (a plaque bubble with a brass pointer) once per player, the first time each moment happens:
- first lock window: "Tap a die to lock it. Locks are final.";
- first lock: "Locked! The rest re-roll when the timer runs out.";
- first combo: "<COMBO> = <c> chips × <m> mult. Bigger combos score more.";
- first time HEAT drops below max: "Heat: lock sooner for a bigger multiplier.";
- first shop: "Charms change how you score. Tap any icon to read it.";
- first boss window: "Boss: lock windows are half as long."

Only one tip shows at a time.

Tips never pause the game or take input. Any tap dismisses the tip and still reaches the die or button underneath. Tips hide after 6 s.

Seen tips persist with the settings. Settings offers "Tips: On / Off" and "Show tips again". Headless tests and the playthrough harness never read or write the player's settings file.

#### Scenario: Once only
- **WHEN** the first lock window opens, and later another one
- **THEN** the lock tip shows the first time only

#### Scenario: Tip never blocks a lock
- **GIVEN** the lock tip is showing
- **WHEN** the player taps a die
- **THEN** the die locks and the tip closes
