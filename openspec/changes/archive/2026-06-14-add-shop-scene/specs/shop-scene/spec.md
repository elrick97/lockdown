## ADDED Requirements

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
Pressing RE-ROLL SHALL replace all unsold offer slots with a new set of stub offers and deduct the reroll cost from gold. Already-purchased slots remain sold.

#### Scenario: Re-roll refreshes slots
- **WHEN** the player presses RE-ROLL with sufficient gold
- **THEN** all unsold offer cards update to new stub offers and gold decreases by `ShopConfig.reroll_cost`

### Requirement: CONTINUE advances the run
Pressing CONTINUE SHALL transition from `ShopScene` back to `ThrowScene`, beginning the next ante. The CONTINUE button is always enabled (the player may leave without buying).

#### Scenario: Continue transitions scene
- **WHEN** the player presses CONTINUE
- **THEN** the scene changes to `ThrowScene` with the next ante's target loaded

### Requirement: Shop layout is code-driven
All Control anchors in `ShopScene` SHALL be set in `_apply_layout()` at runtime, matching the pattern in `ThrowScene`, to survive the Android export anchor-stripping behaviour.

#### Scenario: Layout correct on Android
- **WHEN** the APK runs on a real Android device
- **THEN** gold label, offer cards, RE-ROLL, and CONTINUE buttons are all visible and tappable within the portrait viewport
