## Why

UI/UX audit findings F1, F2 and F4 (`docs/uiux-audit-2026-10-06.md`):
- **F1:** a disabled BUY looks almost the same as an enabled one and gives no reason why. Not enough gold and full charm slots are both silent; tapping does nothing.
- **F2:** buying is the run's big "collect" moment, but it only greys the card out.
- **F4:** "YOUR DICE" is a text line, and carved dice read like debug names ("Wild 6 (Bone)").

Feedback for invalid actions is basic game-feel hygiene (Juice it or lose it; Norman's signifiers). PRD trace: §2 *Collect & unlock*, *Readable depth*; §4.2 shop.

## What Changes

- **The BUY button says why it can't buy:**
  - "NEED 3g" when you can't afford it, with the price in the card title dimmed red;
  - "SLOTS FULL" for a charm when all 5 slots are taken;
  - "SOLD" once bought.

  Tapping a disabled BUY wiggles it and pulses the gold plaque, and the status line states the reason.
- **Purchase payoff:**
  - The bought item's icon flies from the card into its place: the next charm socket, the YOUR DICE row, or (trinkets) the gold plaque area.
  - It lands with a punch and sparks, and the gold readout ticks down.
- **YOUR DICE as icons:** a row of die icons, one per kind, each with a ×count badge (Bone, Iron, Glass and carved dice), using the shop icons. Bone gets its own Blender coaster icon. Tapping one opens the inspect card.
- **Carved-die names:** they read "Bone die · Wild on 6", "Bone die · Gem on 5" and "Bone die · Spark on 4".

## Capabilities

### Modified Capabilities
- `shop-scene`: invalid-state labels and feedback, the purchase fly-in, and the YOUR DICE icon row.

## Impact

- `shop_scene.gd`, `ui_style.gd`, the carved die `.tres` display names, a Blender `bone` shop icon, and `DiceBag` (read-only grouped counts for the icon row).
- No price or rule change.
