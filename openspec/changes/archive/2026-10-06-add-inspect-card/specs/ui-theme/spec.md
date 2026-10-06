## ADDED Requirements

### Requirement: Shared inspect card
Every item the player can own or buy SHALL be inspectable through one shared inspect card (`InspectCard`):
- a leather panel, 980 px wide, over a 45% dark scrim;
- the item's icon at 150 px;
- its name;
- a type tag: "CHARM · always on", "<MATERIAL> DIE · joins your bag", "CARVED DIE · joins your bag" or "TRINKET · one use, during a lock window";
- the full rule text, wrapped inside the card;
- the cost, in the shop.

It opens on a tap of:
- a charm slot on the throw screen (card just above the charm row);
- a medallion in the shop's YOUR BUILD row, or an offer's icon (card in the band above the offers);
- a medallion in the end-of-run build row (card above the build, drawn over the end panel).

Any tap anywhere dismisses it. The card never takes input, so the dismissing tap still reaches what is underneath. During a lock window a die tap still locks, and nothing pauses. The status-line charm text is removed.

#### Scenario: Long rule fits
- **WHEN** the player taps a charm whose rule is longer than one line
- **THEN** the card shows the whole rule wrapped inside its 980 px width

#### Scenario: Locking with the card open
- **GIVEN** the inspect card is open during a lock window
- **WHEN** the player taps a die
- **THEN** the card closes, the die locks, and the window timer never paused

#### Scenario: Shop offer
- **WHEN** the player taps an offer's icon in the shop
- **THEN** the card shows that item's name, type tag, rule and cost
