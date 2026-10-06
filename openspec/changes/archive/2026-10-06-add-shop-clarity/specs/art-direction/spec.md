## ADDED Requirements

### Requirement: Bone die shop icon
`export_shop_icons()` SHALL also render `res://assets/shop/bone.png` (256², the Bone die on its felt coaster) for the YOUR DICE row. Bone dice are never sold.

#### Scenario: Bone icon present
- **WHEN** `check_assets.py` runs
- **THEN** `shop/bone.png` is 256×256
