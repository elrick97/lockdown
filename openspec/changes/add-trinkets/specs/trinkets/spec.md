## ADDED Requirements

### Requirement: Trinket is a one-shot consumable with activation hook
`Trinket` SHALL be a `Resource` subclass with `display_name`, `description`, `cost`, and a single `activate(controller: ThrowController) -> void` method. On activation the trinket is consumed (removed from `TrinketInventory`).

#### Scenario: Trinket consumed on activation
- **GIVEN** Re-Tumble is in slot 1 during a lock window
- **WHEN** its button is pressed
- **THEN** `activate()` runs once and the trinket is removed from `TrinketInventory`

### Requirement: TrinketInventory holds at most 2 trinkets
`TrinketInventory` SHALL enforce a `MAX_SLOTS = 2` cap. `add_trinket()` returns `false` if full.

#### Scenario: Inventory cap enforced
- **WHEN** `TrinketInventory` already holds 2 trinkets
- **THEN** `add_trinket()` returns `false` and the inventory is unchanged

### Requirement: M1 trinkets — Re-Tumble and Freeze Timer
The game SHALL ship two trinkets as `.tres` resources:
- **Re-Tumble** (cost: 3): activatable during any lock window; re-rolls all currently unlocked dice immediately.
- **Freeze Timer** (cost: 4): activatable during any lock window; extends the current window by 2 s.

#### Scenario: Re-Tumble re-rolls unlocked dice
- **GIVEN** Window 1 is active with 4 unlocked dice
- **WHEN** Re-Tumble is activated
- **THEN** the 4 unlocked dice receive new RNG faces and the tumble animation restarts

#### Scenario: Freeze Timer extends window
- **GIVEN** Window 1 has 0.5 s remaining
- **WHEN** Freeze Timer is activated
- **THEN** the window effectively has 2.5 s remaining

### Requirement: Trinket buttons visible during lock windows
`ThrowScene` SHALL show up to 2 trinket buttons during `LOCK_WINDOW` state, each labelled with the trinket name. Buttons are hidden during Tumble and Reroll states.

#### Scenario: Buttons follow the window
- **GIVEN** the player holds two trinkets
- **WHEN** a lock window opens
- **THEN** two buttons labelled with the trinket names appear, and they hide again when the re-roll starts
