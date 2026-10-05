# Design: add-carving-service

## 1. Die inner class (DiceBag)

Add a `Die` inner class inside `dice_bag.gd`:

```gdscript
class Die:
    var material_id: StringName
    var carved_face: int  # -1 = uncarved
    var carve_type: StringName  # &"" = none, &"wild", &"gem", &"spark"

    func _init(mat: StringName, face: int = -1, carve: StringName = &"") -> void:
        material_id = mat
        carved_face = face
        carve_type = carve
```

`DiceBag._dice: Array[DiceBag.Die]` (was `Array[StringName]`).

New method:
```gdscript
func add_carved(material_id: StringName, carved_face: int, carve_type: StringName,
        count: int = 1) -> void
```

`draw()` returns `Array[DiceBag.Die]`. `return_dice(dice: Array[DiceBag.Die])`.

`add(material_id, count)` creates `Die` objects with carved_face=-1, carve_type=&"".

## 2. ThrowController

`_drawn: Array[DiceBag.Die]` (was `Array[StringName]`).

All `_drawn[i]` accesses that read the material string now read `_drawn[i].material_id`.

New signal:
```gdscript
signal carve_activated(die_index: int, carve_type: StringName)
```

In `lock_die(index)`, after setting `locked[index] = true`, before charm hooks:
```gdscript
if _drawn.size() > index:
    var d := _drawn[index]
    if d.carved_face == faces[index] and d.carve_type != &"":
        carve_activated.emit(index, d.carve_type)
```

In `_resolve()`, build `carve_types` parallel array:
```gdscript
var carve_types: Array[StringName] = []
for i in faces.size():
    var d := _drawn[i] if i < _drawn.size() else null
    if d != null and d.carved_face == faces[i] and d.carve_type != &"":
        carve_types.append(d.carve_type)
    else:
        carve_types.append(&"")
result.carve_types = carve_types
```

## 3. ThrowResult

```gdscript
var carve_types: Array[StringName] = []
```

## 4. ScoringEngine

After building `locked` array (existing skips shattered), before pip loop:

```gdscript
# Gem: +20 chips per locked die showing its carved Gem face
for d in locked:
    if d.idx < result.carve_types.size() and result.carve_types[d.idx] == &"gem":
        breakdown.charm_chips += 20

# Wild: substitution for combo detection
var wild_indices: Array[int] = []
var base_faces: Array[int] = []
for d in locked:
    base_faces.append(d.face)
    if d.idx < result.carve_types.size() and result.carve_types[d.idx] == &"wild":
        wild_indices.append(base_faces.size() - 1)

if wild_indices.is_empty():
    breakdown.combos = _detect_combos(base_faces)
else:
    breakdown.combos = _best_wild_combos(base_faces, wild_indices)
```

`_best_wild_combos(faces, wild_slots)`: iterate all combinations of face values (1-6) for each wild slot, call `_detect_combos` on each substitution, keep the result with the highest `base_score`. Bounded by 6^N, N ≤ 2 → max 36 calls.

## 5. ThrowScene

Connect `carve_activated` in `_make_controller()`:
```gdscript
ctrl.carve_activated.connect(_on_carve_activated)
```

Handler:
```gdscript
func _on_carve_activated(_die_index: int, carve_type: StringName) -> void:
    if carve_type == &"spark":
        _controller.freeze_window(-0.5)  # negative subtracts from _accumulated → adds time
```

## 6. ShopScene

Add to `_CARVED_DIE_PATHS`:
```
res://resources/carved_dice/wild_6_bone.tres
res://resources/carved_dice/gem_5_bone.tres
res://resources/carved_dice/spark_4_bone.tres
```

Each is a new `CarvedDieOffer` Resource:
```gdscript
class_name CarvedDieOffer
extends Resource
@export var display_name: String = ""
@export var description: String = ""
@export var cost: int = 0
@export var material_id: StringName = &"standard"
@export var carved_face: int = 6
@export var carve_type: StringName = &"gem"
```

Shop offer pool builds `{"kind": "carved_die", "res": CarvedDieOffer}` entries.

On buy: `RunCoordinator.bag.add_carved(offer.material_id, offer.carved_face, offer.carve_type)`.

No inventory cap — carved dice go into the bag (unlimited by design).

## 7. freeze_window negative argument

`freeze_window(-0.5)` sets `_accumulated = maxf(0.0, _accumulated - (-0.5)) = _accumulated + 0.5`.

**Wait** — the current implementation is `_accumulated = maxf(0.0, _accumulated - duration)`. With duration=-0.5, this becomes `maxf(0.0, _accumulated + 0.5)` which correctly ADDS 0.5s. No code change needed; negative duration is already handled.

## File changes summary

| File | Change |
|------|--------|
| `scripts/dice_bag.gd` | Add `Die` inner class; change `_dice` type; new `add_carved()`; update `draw()`/`return_dice()`/`add()` |
| `scripts/throw_controller.gd` | Change `_drawn` type; add `carve_activated` signal; emit on lock; build carve_types in `_resolve()` |
| `scripts/throw_result.gd` | Add `carve_types: Array[StringName]` |
| `scripts/scoring_engine.gd` | Gem +20 chips; Wild try-all substitution in combo detection |
| `scenes/throw/throw_scene.gd` | Connect `carve_activated`; handle Spark in handler |
| `scripts/carved_die_offer.gd` | New resource class |
| `resources/carved_dice/` | 3 new `.tres` files |
| `scripts/shop_scene.gd` | `_CARVED_DIE_PATHS`; pool entry `"carved_die"`; buy handler |
| `tests/test_carving.gd` | New GUT test file |
