## ADDED Requirements

### Requirement: Every offer shows its icon
Each shop offer card SHALL show its item's icon left of the text, at medallion size:
- **Charm offers:** the charm medallion.
- **Die-material and carved-die offers:** the die on its coaster.
- **Trinket offers:** the trinket chip.

The icon comes from the offered resource's `icon` field, so adding a sellable item with an icon needs no shop code.

#### Scenario: Mixed roll
- **WHEN** the shop offers a charm, a die and a trinket
- **THEN** all three cards show an icon, and the three item families look distinct
