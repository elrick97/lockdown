# shop-scene Specification

## Purpose
The shop shown between antes: offers, re-roll and continue.
## Requirements
### Requirement: Shop displayed after every ante clear (except final)
After the ante cascade completes and the run is not over, the system SHALL transition to `ShopScene`. After the player presses CONTINUE, the system SHALL transition back to `ThrowScene` with the next ante target.

#### Scenario: Shop appears after ante 1 clears
- **WHEN** the player clears ante 1 of 3
- **THEN** `ShopScene` loads, displaying the player's current gold and 3 offer slots

#### Scenario: No shop after final ante
- **WHEN** the player clears the final ante
- **THEN** the run-won screen is shown; `ShopScene` is NOT loaded

### Requirement: Shop displays gold and 3 offer slots
`ShopScene` SHALL display the player's current gold balance and exactly 3 offer cards. Each card shows the offer label, cost, and a BUY button. BUY buttons for offers the player cannot afford SHALL be disabled.

#### Scenario: Offer cards rendered
- **WHEN** `ShopScene` loads
- **THEN** three offer cards are visible, each showing a label and a cost

#### Scenario: Unaffordable offer is greyed out
- **WHEN** the player has 1 gold and an offer costs 3
- **THEN** the BUY button for that offer is disabled

### Requirement: RE-ROLL refreshes unsold offers
Pressing RE-ROLL SHALL replace all unsold offer slots with a new set of `CharmEffect` resources drawn from the run's charm pool (shuffled via `RngService.shuffle_shop()`). Already-purchased slots remain sold. The reroll cost is deducted from gold as before.

#### Scenario: Re-roll refreshes slots with real charms
- **WHEN** the player presses RE-ROLL with sufficient gold
- **THEN** all unsold offer cards update to new `CharmEffect` entries from the pool and gold decreases by `ShopConfig.reroll_cost`

### Requirement: CONTINUE advances the run
Pressing CONTINUE SHALL transition from `ShopScene` back to `ThrowScene`, beginning the next ante. The CONTINUE button is always enabled (the player may leave without buying).

#### Scenario: Continue transitions scene
- **WHEN** the player presses CONTINUE
- **THEN** the scene changes to `ThrowScene` with the next ante's target loaded

### Requirement: Shop offers real CharmEffect resources
`ShopScene` SHALL populate its offer pool from all `CharmEffect` resources defined in the M1 charm catalog (currently 12 entries). Charms already owned by `RunCoordinator.inventory` SHALL be excluded from the pool. Each offer card SHALL display `CharmEffect.display_name`, `CharmEffect.description`, and `CharmEffect.cost`. Offer pool order SHALL be determined by `RngService.shuffle_shop()` so shop contents are seeded and reproducible.

#### Scenario: Offer cards show charm metadata
- **WHEN** `ShopScene` loads with the full 12-charm pool (minus owned charms)
- **THEN** up to 3 cards are visible, each showing the charm's `display_name` and `cost`

#### Scenario: Owned charms excluded from pool
- **WHEN** the player already owns Quick Draw
- **THEN** Quick Draw does not appear as an offer in subsequent shop visits

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

### Requirement: Shop layout is code-driven
All Control anchors in `ShopScene` SHALL be set in `_apply_layout()` at runtime, matching the pattern in `ThrowScene`, to survive the Android export anchor-stripping behaviour.

#### Scenario: Layout correct on Android
- **WHEN** the APK runs on a real Android device
- **THEN** gold label, offer cards, RE-ROLL, and CONTINUE buttons are all visible and tappable within the portrait viewport

### Requirement: Every offer shows its icon
Each shop offer card SHALL show its item's icon left of the text, at medallion size:
- **Charm offers:** the charm medallion.
- **Die-material and carved-die offers:** the die on its coaster.
- **Trinket offers:** the trinket chip.

The icon comes from the offered resource's `icon` field, so adding a sellable item with an icon needs no shop code.

#### Scenario: Mixed roll
- **WHEN** the shop offers a charm, a die and a trinket
- **THEN** all three cards show an icon, and the three item families look distinct

