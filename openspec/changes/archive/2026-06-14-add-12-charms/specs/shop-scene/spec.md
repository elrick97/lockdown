## MODIFIED Requirements

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
