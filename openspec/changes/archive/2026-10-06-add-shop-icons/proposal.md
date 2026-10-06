## Why

After `add-charm-icons`, only charm offers carried art. Dice-material, carved-die and trinket offers were text-only cards, so a shop roll mixed illustrated and plain cards. Trinket buttons on the throw screen were plain text too. The owner's direction (2026-10-06) is to keep improving style and UI/UX, and to treat flat UI as unfinished. PRD trace: §4.2 shop, §5 art direction, §2 *Readable depth* (tell the item type at a glance).

**Pillars served:** *Readable depth*: three item families are now visually distinct:
- **Charms:** enamel medallions.
- **Dice:** the actual die on a felt coaster.
- **Trinkets:** walnut gaming chips.

*Collect & unlock*: every purchasable is an object.

## What Changes

- **`icon` field:** `DiceMaterial`, `Trinket` and `CarvedDieOffer` each get `@export var icon: Texture2D`. The seven sellable resources point at `res://assets/shop/<id>.png`. The shop already reads `res.get("icon")`, so cards pick the icons up with no shop logic change.
- **Blender icons:** `export_shop_icons()` renders seven 256² icons with alpha.
  - **Dice** (Iron, Glass, Wild 6, Gem 5, Spark 4): the shipped die mesh with its material atlas, in 3/4 view on a dark felt coaster with a brass rim. Carved dice show the carved face up over a faint amber ring.
  - **Trinkets** (Re-Tumble, Freeze Timer): a walnut gaming chip with brass edge inserts and an ivory emblem. The emblems are chasing arrows for Re-Tumble and a paused stopwatch for Freeze Timer.
- **Trinket buttons:** buttons on the throw screen show their chip beside the name.

## Capabilities

### Modified Capabilities
- `shop-scene`: every offer card shows its item's icon.
- `trinkets`: trinkets carry an icon; trinket buttons show it.
- `art-direction`: adds the production shop icons.

## Impact

- Three scripts get an `icon` export, seven `.tres` files are updated, plus `lockdown_art.py`, `assets/shop/` (LFS), the throw-scene trinket buttons, `check_assets.py`, and CI LFS includes.
- No rule or price change.

## Non-goals

- Bone dice icon (never sold).
- Collection journal (M2).
