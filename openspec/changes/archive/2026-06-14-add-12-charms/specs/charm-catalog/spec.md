## ADDED Requirements

### Requirement: M1 charm catalog defines 12 charms
The game SHALL ship 12 charm types for the M1 vertical slice. Each charm is a `CharmEffect` subclass saved as a `.tres` resource under `res://resources/charms/`. Costs and bonus amounts are **named tunables** (current values shown); balance changes are spec deltas, not silent code edits.

#### Scenario: All 12 charms loadable
- **WHEN** each `.tres` file in `res://resources/charms/` is loaded as a `CharmEffect`
- **THEN** `display_name`, `description`, and `cost` are non-empty and all four hook methods are callable without error

### Requirement: Speed archetype — Quick Draw (cost: 6)
If every die in the locked set was locked in Window 1, add `charm_mult += 2.0`.

#### Scenario: All W1 locks trigger bonus
- **WHEN** all tray dice are locked in Window 1 with a Pair of 4s at Heat ×1.0
- **THEN** `charm_mult` is 2.0 and the score is `(8 + 10) × (1 + 2.0) × 1.0` = 54

#### Scenario: Mixed windows suppress bonus
- **WHEN** at least one die was locked in Window 2 or 3
- **THEN** `charm_mult` remains 0.0

### Requirement: Speed archetype — Hair Trigger (cost: 4)
For each die locked in Window 1, add `charm_chips += 5`.

#### Scenario: Two W1 locks add 10 chips
- **WHEN** exactly 2 dice are locked in Window 1 (others in later windows)
- **THEN** `charm_chips` is 10

#### Scenario: No W1 locks give no chips
- **WHEN** all dice are locked in Window 2 or 3
- **THEN** `charm_chips` remains 0

### Requirement: Speed archetype — Adrenaline (cost: 4)
If at least 3 dice are locked in Window 1, add `charm_mult += 1.0`.

#### Scenario: Threshold met gives mult
- **WHEN** exactly 3 dice are locked in Window 1 (remaining in later windows)
- **THEN** `charm_mult` is 1.0

#### Scenario: Fewer than 3 W1 locks give no mult
- **WHEN** only 2 dice are locked in Window 1
- **THEN** `charm_mult` remains 0.0

### Requirement: Slow archetype — Patient Zero (cost: 4)
For each die locked in Window 3, add `charm_chips += 5`. (Intended final rule: double that die's Pip contribution. Deferred pending CharmContext face-by-slot extension.)

#### Scenario: W3 locks add chips
- **WHEN** 4 dice are force-locked in Window 3
- **THEN** `charm_chips` is 20

#### Scenario: No W3 locks give no chips
- **WHEN** all dice are locked in Windows 1 or 2
- **THEN** `charm_chips` remains 0

### Requirement: Slow archetype — Ice Cold (cost: 6)
If zero dice were locked in Window 1, add `charm_mult += 3.0`.

#### Scenario: No W1 locks trigger bonus
- **WHEN** the locked set has all dice locked in Windows 2 and 3 only
- **THEN** `charm_mult` is 3.0

#### Scenario: Any W1 lock suppresses bonus
- **WHEN** at least one die was locked in Window 1
- **THEN** `charm_mult` remains 0.0

### Requirement: Value archetype — Loaded (cost: 4)
For each die in the locked set showing face 6, add `charm_chips += 6`.

#### Scenario: Two 6s add 12 chips
- **WHEN** the locked set contains two 6s
- **THEN** `charm_chips` is 12

#### Scenario: No 6s give no chips
- **WHEN** no locked die shows a 6
- **THEN** `charm_chips` remains 0

### Requirement: Value archetype — Big Bucks (cost: 3)
For each die in the locked set showing face 5 or 6, add `charm_chips += 3`.

#### Scenario: One 5 and one 6 add 6 chips
- **WHEN** the locked set contains one 5 and one 6
- **THEN** `charm_chips` is 6

#### Scenario: Low faces give no chips
- **WHEN** all locked dice show faces 1–4
- **THEN** `charm_chips` remains 0

### Requirement: Value archetype — Precision (cost: 6)
If every die in the locked set shows the same face value, add `charm_mult += 2.0`.

#### Scenario: All-same-face triggers bonus
- **WHEN** the locked set is [4, 4, 4, 4] (all 4s)
- **THEN** `charm_mult` is 2.0

#### Scenario: Mixed faces suppress bonus
- **WHEN** the locked set contains at least two different face values
- **THEN** `charm_mult` remains 0.0

### Requirement: Inversion archetype — Snake Charmer (cost: 5)
If the locked set contains exactly two 1s and the leading combo in the winning partition is a Pair, set `combo_mult = 4` and `bonus_chips = 0`.

#### Scenario: Snake eyes give ×4 Mult
- **WHEN** the locked set is [1, 1] at Heat ×1.0
- **THEN** `combo_mult` is 4, `bonus_chips` is 0, and the score is `(2 + 0) × 4 × 1.0` = 8

#### Scenario: Non-1 pair unaffected
- **WHEN** the locked set is [3, 3]
- **THEN** `combo_mult` and `bonus_chips` are unchanged

### Requirement: Combo archetype — Collector (cost: 5)
Add `charm_mult += 1.0` for each distinct face value present in the locked set.

#### Scenario: All-different 6-die throw
- **WHEN** the locked set is [1, 2, 3, 4, 5, 6] (all distinct)
- **THEN** `charm_mult` is 6.0

#### Scenario: All-same suppresses bonus
- **WHEN** the locked set is [4, 4, 4, 4] (one distinct value)
- **THEN** `charm_mult` is 1.0

### Requirement: Combo archetype — High Roller (cost: 7)
If the leading combo in the winning partition is Quad or Quint+, add `charm_chips += 60`.

#### Scenario: Quad triggers bonus
- **WHEN** the locked set resolves with a Quad as the top combo
- **THEN** `charm_chips` is 60

#### Scenario: Triple does not trigger
- **WHEN** the top combo is a Triple
- **THEN** `charm_chips` remains 0

### Requirement: Combo archetype — Straight Edge (cost: 5)
If the winning partition contains a Small Straight or Large Straight, add `charm_mult += 3.0`.

#### Scenario: Large Straight triggers bonus
- **WHEN** the locked set is [1, 2, 3, 4, 5, 6] resolving as a Large Straight
- **THEN** `charm_mult` is 3.0

#### Scenario: No straight gives no mult
- **WHEN** the winning partition contains no Small or Large Straight
- **THEN** `charm_mult` remains 0.0
