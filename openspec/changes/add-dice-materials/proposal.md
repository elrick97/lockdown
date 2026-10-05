# Proposal: add-dice-materials

## What
Add a `DiceMaterial` resource system and implement the 3 M1 materials: Bone (baseline), Iron (−1 pip offset, slower tumble), and Glass (×2 pips, shatters on re-roll). Add dice to the shop offer pool so the player can buy them between antes.

## Why
PRD §4.2: "3 materials for vertical slice". Materials are a core pillar of the collect-and-unlock loop and a primary source of build diversity alongside charms.

## Capabilities affected
- **NEW** `dice-materials` spec — DiceMaterial resource, per-die pip adjustments, Glass shatter
- **MODIFIED** `shop-scene` spec — dice offers alongside charm offers
- **MODIFIED** `throw-loop` spec — shattered Glass dice become dead slots

## Non-goals
- Gold, Echo, Cursed materials (M2)
- Carved faces (separate change)
- Balance sim run (no new charms — materials only)
