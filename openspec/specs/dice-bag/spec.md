# dice-bag Specification

## Purpose
The run's dice bag: which dice exist, how a throw draws from them, and the tray hard cap.
## Requirements
### Requirement: Bag holds the run's dice
The run SHALL own a bag of dice. For this change the bag contains identical standard d6 dice; the count is the named tunable `starting_bag_size` (current value: **8**). Composition rules (materials, added/removed dice) arrive in later changes.

#### Scenario: Bag initialized at run start
- **WHEN** a run starts
- **THEN** the bag contains `starting_bag_size` standard dice

### Requirement: Throw draws from the bag
A throw SHALL draw `draw_size` dice (named tunable, current value: **6**) from the bag onto the tray, selected via the seeded RNG `bag` stream, without replacement within the throw. Drawn dice SHALL return to the bag when the throw resolves.

#### Scenario: Standard draw
- **WHEN** a throw starts with at least `draw_size` dice in the bag
- **THEN** exactly `draw_size` dice move from the bag to the tray

#### Scenario: Bag smaller than draw size
- **WHEN** a throw starts with fewer than `draw_size` dice in the bag
- **THEN** all remaining bag dice are drawn and the throw proceeds with the smaller tray

#### Scenario: Dice return on resolve
- **WHEN** a throw resolves
- **THEN** every drawn die is back in the bag before the next throw's draw

### Requirement: Tray hard cap
The tray SHALL never hold more than 8 dice (settled rule, PRD §3.2). Any current or future draw-size modifier is clamped so the cap holds.

#### Scenario: Draw size modified above cap
- **WHEN** `draw_size` plus modifiers would exceed 8
- **THEN** exactly 8 dice are drawn

