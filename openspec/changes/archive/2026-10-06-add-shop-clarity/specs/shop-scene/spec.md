## ADDED Requirements

### Requirement: BUY says why it can't buy
Each offer's BUY button SHALL name its state, at a fixed width:
- "BUY";
- "SOLD";
- "SLOTS FULL" (a charm with 5/5 charms, or a trinket with full trinket slots);
- "NEED <n>g" (n = the gold still missing), with the card's name and price tinted red.

Tapping a disabled BUY that isn't sold SHALL wiggle it and put the reason in the status line ("Need 3 more gold" or "Slots full: 5 / 5"). Need-gold taps also pulse the gold readout.

#### Scenario: Broke
- **WHEN** the shop opens with 0 gold
- **THEN** every offer's button reads "NEED <cost>g"

#### Scenario: Tap a blocked offer
- **WHEN** the player taps a "NEED 3g" button
- **THEN** it wiggles and the status reads "Need 3 more gold"

### Requirement: Purchases land with a payoff
Buying an offer SHALL fly its icon from the card to where it lands, then punch the target and burst brass sparks:
- a charm lands in its build socket;
- a die lands on its icon in YOUR DICE;
- anything else lands on the gold readout.

The gold readout ticks down to the new total.

#### Scenario: Buy a charm
- **WHEN** the player buys a charm
- **THEN** its medallion flies into the next socket, the gold ticks down, and the button reads "SOLD"

### Requirement: YOUR DICE as die icons
YOUR DICE SHALL show one die icon per kind in the bag, using `DiceBag.groups()` and each kind's shop icon (Bone has its own), with a "×count" badge. The text summary sits under the icons. Tapping an icon opens the inspect card for that die. Carved dice are named "Bone die · <Carve> on <face>".

#### Scenario: Mixed bag
- **WHEN** the bag holds the starting Bone dice, 2 Glass and a Wild 6
- **THEN** YOUR DICE shows three icons with "×8", "×2" and "×1"
