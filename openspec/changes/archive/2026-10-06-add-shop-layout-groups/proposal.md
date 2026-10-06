## Why

The shop had a wide empty band between the owned charms and a floating "Choose an upgrade" heading, and it never told you what dice you own. That matters now that dice materials and carved dice are bought there. The owner's direction (2026-10-06) is to keep improving style and UI/UX. PRD trace: §4.2 shop, §2 *Readable depth* (know your build before buying).

**Pillars served:** *Readable depth*: you see both halves of your build, charms and dice, before choosing. *One thumb, one screen*: the BUY buttons stay in the bottom 55%.

## What Changes

- **Two groups:**
  - Top: "YOUR BUILD" (medallions, then the charm line) and "YOUR DICE" (a bag summary such as "6 Bone · 1 Glass · 1 Gem 5").
  - Bottom: the offer heading, sitting directly on the offer cards.
- **Bag summary:** `DiceBag.summary()` is a read-only display string, grouped in order of first appearance, with carved dice named by carve and face. It refreshes after every purchase.

## Capabilities

### Modified Capabilities
- `shop-scene`: the layout groups and the YOUR DICE line.

## Impact

- `shop_scene.gd` and `dice_bag.gd` (`summary()`).
- No economy change.
