## MODIFIED Requirements

### Requirement: RE-ROLL refreshes unsold offers
Pressing RE-ROLL SHALL replace all unsold offer slots with a new set of `CharmEffect` resources drawn from the run's charm pool (shuffled via `RngService.get_shop()`). Already-purchased slots remain sold. The reroll cost is deducted from gold as before.

#### Scenario: Re-roll refreshes slots with real charms
- **WHEN** the player presses RE-ROLL with sufficient gold
- **THEN** all unsold offer cards update to new `CharmEffect` entries from the pool and gold decreases by `ShopConfig.reroll_cost`

## ADDED Requirements

### Requirement: Shop offers real CharmEffect resources
`ShopScene` SHALL populate its offer pool from `CharmInventory`-compatible `CharmEffect` resources loaded from `res://resources/charms/`. Each offer card SHALL display `CharmEffect.display_name`, `CharmEffect.description`, and `CharmEffect.cost`. Offer pool order SHALL be determined by `RngService.get_shop()` so shop contents are seeded and reproducible.

#### Scenario: Offer cards show charm metadata
- **WHEN** `ShopScene` loads with Quick Draw, Loaded, and Snake Charmer in the pool
- **THEN** three cards are visible with those names and their respective costs

#### Scenario: Offer pool is seeded
- **WHEN** two runs use the same seed and no re-rolls are pressed
- **THEN** the same charm order appears in the shop on both runs

### Requirement: Buying a charm adds it to CharmInventory
When the player buys a charm offer, `ShopScene` SHALL call `RunCoordinator.inventory.add_charm(charm)`. If the inventory is full (`is_full()` returns `true`), the BUY button SHALL be disabled regardless of gold.

#### Scenario: Bought charm enters inventory
- **WHEN** the player buys Quick Draw from the shop
- **THEN** `RunCoordinator.inventory.iter_charms()` includes the Quick Draw instance

#### Scenario: BUY disabled when inventory full
- **WHEN** the player already has 5 charms equipped
- **THEN** all BUY buttons in the shop are disabled, even if the player can afford them
