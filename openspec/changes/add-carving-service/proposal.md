# Proposal: add-carving-service

## What
Add a carving service for M1: the shop sells pre-carved dice that permanently mark one face of one die with a carved effect (Wild, Gem, or Spark). Buying a carved die adds it to the player's bag.

## Why
PRD §4.3 lists carved faces as a core M1 system — the "deck-editing analog" for dice. Carving lets the player reshape their roll distribution in a targeted, permanent way, adding strategic depth to the shop decision space (charm vs. die material vs. die carving). M1 target: Wild, Gem, Spark.

## Scope

### In
- `Die` inner class in `DiceBag` bundling `material_id`, `carved_face`, `carve_type`
- `DiceBag.add_carved(material_id, carved_face, carve_type)` and updated `draw()`/`return_dice()`
- `ThrowResult.carve_types: Array[StringName]` parallel array
- `ThrowController` emits `carve_activated(index, carve_type: StringName)` on lock
- `ScoringEngine` handles Wild (try-all, O(6^N) bounded by N ≤ 2) and Gem (+20 chips)
- `ThrowScene` handles Spark (`freeze_window(-0.5)` on `carve_activated` signal)
- Shop offers preset carved-die packages: Wild-6 Bone (6g), Gem-5 Bone (4g), Spark-4 Bone (5g)
- GUT tests: Wild combo detection, Gem chip addition, Spark timing, DiceBag Die identity

### Out of M1
- Bomb and Skull carved faces (M2 per PRD §4.3)
- Picker modal for choosing which bag-die to carve (M2)
- Carving non-Bone dice in shop (M2 — keep shop offers simple)

## PRD trace
PRD §4.3 "Carved faces — Replace a pip face with: Wild (any value), Gem (+20 Chips), Spark (+0.5 s to next window)". Design pillar: Readable Depth (§2) — the carved face is visually distinct on the die face, giving experienced players a plan.

## Risks
- Wild try-all: O(6^N) combo scoring. N ≤ 2 in M1 (max 2 carved dice can appear in a single draw of 6), so ≤ 36 iterations — negligible.
- DiceBag refactor touches ThrowController `_drawn` type; all callers need updating.
