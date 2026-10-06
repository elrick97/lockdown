## ADDED Requirements

### Requirement: Shop shows what you have, then what you can buy
The shop SHALL group its screen into two parts:
- **What you have, at the top:** the gold plaque; "YOUR BUILD" (charm medallions and the "Charms n / 5: …" line); and "YOUR DICE", with `DiceBag.summary()` such as "6 Bone · 1 Glass · 1 Gem 5". The summary groups dice by material, or by carve and face for carved dice, in order of first appearance.
- **What you can buy, below:** the offer heading, placed directly above the offer cards.

The dice line SHALL refresh after every purchase. Every BUY stays in the bottom 55% of the screen.

#### Scenario: Dice listed
- **GIVEN** the bag holds the starting Bone dice, 1 Glass and a Gem 5
- **WHEN** the shop opens
- **THEN** YOUR DICE reads "<n> Bone · 1 Glass · 1 Gem 5"

#### Scenario: Refresh after buying a die
- **WHEN** the player buys an Iron die
- **THEN** the dice line updates to include Iron
