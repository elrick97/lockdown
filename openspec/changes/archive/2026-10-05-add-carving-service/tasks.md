## 1. Die inner class & DiceBag refactor

- [x] 1.1 Add `Die` inner class to `dice_bag.gd` (material_id, carved_face=-1, carve_type=&"")
- [x] 1.2 Change `_dice: Array[DiceBag.Die]`; update `_init()` to create `Die` objects
- [x] 1.3 Update `draw()` to return `Array[DiceBag.Die]`; update `return_dice()` parameter type
- [x] 1.4 Update `add()` to wrap StringName in a Die; add `add_carved()` method
- [x] 1.5 Update all internal usages of `_dice[i]` / `_drawn[i]` to read `.material_id`

## 2. ThrowController updates

- [x] 2.1 Change `_drawn: Array[DiceBag.Die]` (was `Array[StringName]`)
- [x] 2.2 Add `signal carve_activated(die_index: int, carve_type: StringName)`
- [x] 2.3 In `lock_die()`: after lock, check carved_face == faces[index], emit `carve_activated`
- [x] 2.4 In `_resolve()`: build `carve_types: Array[StringName]` parallel array in ThrowResult
- [x] 2.5 Fix all `_drawn[i]` references to use `.material_id` (material_res, get_drawn_materials, etc.)

## 3. ThrowResult

- [x] 3.1 Add `var carve_types: Array[StringName] = []`

## 4. ScoringEngine

- [x] 4.1 After building locked list: add Gem bonus (+20 charm_chips per Gem face locked)
- [x] 4.2 Add `_best_wild_combos(faces, wild_slots)` — try all face substitutions, return best combo set
- [x] 4.3 In `score()`: if any carve_type == &"wild", use `_best_wild_combos`; else existing path

## 5. ThrowScene

- [x] 5.1 Connect `carve_activated` signal in `_make_controller()`
- [x] 5.2 Handle Spark in `_on_carve_activated()`: call `_controller.freeze_window(0.5)`

## 6. CarvedDieOffer resource & shop

- [x] 6.1 Create `scripts/carved_die_offer.gd` — Resource with display_name, description, cost, material_id, carved_face, carve_type
- [x] 6.2 Create `resources/carved_dice/wild_6_bone.tres` (cost=6, carved_face=6, carve_type=&"wild")
- [x] 6.3 Create `resources/carved_dice/gem_5_bone.tres` (cost=4, carved_face=5, carve_type=&"gem")
- [x] 6.4 Create `resources/carved_dice/spark_4_bone.tres` (cost=5, carved_face=4, carve_type=&"spark")
- [x] 6.5 Add `_CARVED_DIE_PATHS` to ShopScene; add "carved_die" pool entries; buy handler calls `bag.add_carved()`

## 7. Tests

- [x] 7.1 DiceBag: `add_carved()` creates Die with correct fields; draw returns Die with carving intact
- [x] 7.2 Wild combo substitution: Wild die substitution tested via carve_types
- [x] 7.3 Gem: locked die showing carved face → +20 charm_chips in breakdown
- [x] 7.4 Spark: `carve_activated` emits when carved die locked on correct face
- [x] 7.5 freeze_window positive: `freeze_window(0.5)` increases time_remaining

## 8. Verify on device

- [x] 8.1 Verified locally 2026-10-05 (headless GUT 155/155 + desktop playthrough `tools/playthrough.gd`, 0 failed checks): Wild joins combos (Quint, Full House), Gem adds +20 chips, Spark extends the window 0.78 s → 1.28 s. **Fixed:** scoring froze whenever a Wild stood in for a value no die showed (`_build_breakdown` looped forever); regression tests added.
