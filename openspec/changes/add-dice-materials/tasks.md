## 1. DiceMaterial resource

- [x] 1.1 Create `scripts/dice_material.gd` — DiceMaterial extends Resource with material_id, pip_offset, pip_multiplier, shatter_on_reroll, tumble_duration_factor, cost, display_name, description
- [x] 1.2 Create `resources/dice_materials/bone.tres` — cost=0, pip_offset=0, pip_multiplier=1, shatter=false, factor=1.0
- [x] 1.3 Create `resources/dice_materials/iron.tres` — cost=4, pip_offset=-1, pip_multiplier=1, shatter=false, factor=1.4
- [x] 1.4 Create `resources/dice_materials/glass.tres` — cost=6, pip_offset=0, pip_multiplier=2, shatter=true, factor=1.0

## 2. DiceBag

- [x] 2.1 Add `func add(material: StringName, count: int = 1) -> void`

## 3. RunCoordinator

- [x] 3.1 Add `var bag: DiceBag`; initialize in `start_run()` with `DiceBag.new(_throw_config.starting_bag_size)`
- [x] 3.2 `bag` is a public field — ShopScene calls `RunCoordinator.bag.add(mat.material_id)`

## 4. ThrowResult

- [x] 4.1 Add `pip_offsets: Array[int]`, `pip_multipliers: Array[int]`, `shattered: Array[bool]`

## 5. ThrowController

- [x] 5.1 Add `_shattered: Array[bool]` parallel to `faces`; `_material_cache: Dictionary`
- [x] 5.2 Add `_material_res(name: StringName) -> DiceMaterial` loader with cache
- [x] 5.3 In `start_throw()`: reset `_shattered` to all-false
- [x] 5.4 In `_begin_reroll()`: Glass dice shatter (marked _shattered[i]=true) instead of re-rolling
- [x] 5.5 In `_force_lock_remaining()`: skip shattered slots
- [x] 5.6 In `_resolve()`: populate result.pip_offsets, pip_multipliers, shattered; build arrays before clearing _drawn

## 6. ScoringEngine

- [x] 6.1 Filter locked_order to exclude shattered indices
- [x] 6.2 Apply pip formula: `pips += maxi(0, faces[idx] + pip_offsets[idx]) * pip_multipliers[idx]`

## 7. ThrowScene

- [x] 7.1 Use `RunCoordinator.bag` instead of `DiceBag.new(...)` locally
- [x] 7.2 `_tumble_duration_s()` helper uses max tumble_duration_factor across drawn materials

## 8. ShopScene

- [x] 8.1 Add `_MATERIAL_PATHS` constant (iron, glass)
- [x] 8.2 Mixed pool with charm + die entries; buying a die calls `RunCoordinator.bag.add(mat.material_id)`
- [x] 8.3 Inventory-full check only blocks charm purchases, not die purchases

## 9. Tests

- [x] 9.1–9.6 `tests/test_dice_materials.gd` — 7 tests covering Iron pip offset, Glass multiplier, shatter exclusion

## 10. Verify on device

- [ ] 10.1 Build + deploy; buy an Iron die in shop; confirm lower scores; buy a Glass die — confirm high pips but dies disappear on re-roll
