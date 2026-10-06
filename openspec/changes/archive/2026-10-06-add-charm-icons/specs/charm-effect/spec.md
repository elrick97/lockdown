## ADDED Requirements

### Requirement: CharmEffect carries an icon
Each `CharmEffect` SHALL expose `@export var icon: Texture2D`: the charm's medallion, set in its `.tres`. Adding a charm stays a script, a resource and an icon, with no engine edit.

#### Scenario: Icon readable generically
- **WHEN** any screen reads `icon` from a charm in the inventory or the shop pool
- **THEN** it gets the charm's medallion texture without downcasting

### Requirement: Score breakdown records which charms fired
While firing `on_score` hooks in slot order, the scoring engine SHALL compare the breakdown's chips (`bonus_chips + charm_chips`) and mult (`combo_mult + charm_mult`) before and after each hook. Each charm that changed either SHALL be appended to `ScoreBreakdown.charm_triggers` as `{ slot, chips, mult }` (the deltas). This record is presentation-only; it never changes the score.

#### Scenario: Silent charm not recorded
- **GIVEN** Loaded, Hair Trigger and Snake Charmer in slots 0–2, and a pair of 4s locked in Window 1
- **WHEN** the throw is scored
- **THEN** `charm_triggers` holds one entry: slot 1 with chips +10

#### Scenario: Rewrites count as triggers
- **WHEN** Snake Charmer rewrites a snake-eyes Pair's mult
- **THEN** it is recorded in `charm_triggers`
