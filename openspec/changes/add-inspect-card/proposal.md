## Why

UI/UX audit finding E1 (P0): the only way to read a charm mid-run is to tap its slot. That writes "Name: rule" into the 48 px status label, which doesn't wrap: long rules run off both screen edges, and the next status change overwrites them. Dice and trinkets have no inspect at all, and shop medallions and the end-panel build can't be inspected either. Slay the Spire puts a keyword tooltip everywhere a term appears; Marvel Snap uses hold-to-inspect on mobile. PRD trace: §2 *Readable depth*, *Collect & unlock*.

## What Changes

- **One shared inspect card:** a leather card with a brass frame showing:
  - the icon at 160 px;
  - the name;
  - an archetype or type tag (for example "SPEED CHARM", "GLASS DIE", "TRINKET");
  - the full rule text, wrapped at 40 px, with Chips and Mult shown consistently;
  - the cost when shown in the shop.
- **How it opens:** tapping or holding a charm slot, a shop medallion, an offer icon or an end-panel medallion opens it above the item. Tapping anywhere dismisses it.
- **During a lock window:** the card is allowed, never pauses the timer, and never eats a die tap. The card itself takes no input, so taps on dice still lock.
- **Old tooltip removed:** the status-line charm text goes away.

## Capabilities

### Modified Capabilities
- `ui-theme`: adds the inspect card and the places that open it.

## Impact

- New `scripts/inspect_card.gd`, used by the throw scene, the shop and the end panel.
- Content stays data: it reads `display_name`, `description`, `icon` and `cost`.
- Tests: the card shows the right data; long text wraps inside the card; a die tap during a window still locks with the card open; the card dismisses.
