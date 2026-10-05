# Design: add-dice-materials

## DiceMaterial resource

```gdscript
class_name DiceMaterial
extends Resource
@export var display_name: String
@export var pip_offset: int = 0        # added to face value for pip scoring (Iron: -1)
@export var pip_multiplier: int = 1    # multiplies adjusted pip value (Glass: 2)
@export var shatter_on_reroll: bool = false  # Glass: becomes a dead slot on reroll
@export var tumble_speed_factor: float = 1.0  # Iron: 0.75 (longer tumble = easier to read)
@export var cost: int = 5
```

Resources under `res://resources/dice_materials/`: bone.tres, iron.tres, glass.tres.

## ThrowResult changes

Add parallel-to-faces arrays:
- `pip_offsets: Array[int]` — per-slot pip offset (0 for Bone/Glass, -1 for Iron)
- `pip_multipliers: Array[int]` — per-slot pip multiplier (1 for Bone/Iron, 2 for Glass)
- `shattered: Array[bool]` — true for Glass dice that were re-rolled (excluded from scoring)

## ThrowController changes

Track `_materials: Array[StringName]` parallel to `faces` (from `_bag.draw()`). Load material resources lazily via a `_material_cache: Dictionary` keyed on StringName.

On `start_throw()` / re-draw: populate `pip_offsets`, `pip_multipliers` from materials.

On `_begin_reroll()`: for each unlocked die, if its material has `shatter_on_reroll = true`, mark it as shattered (add to `_shattered: Array[bool]`) rather than re-rolling. Shattered dice keep their last face but are excluded from scoring and remain on the tray visually (dead slot).

Force-lock behaviour: shattered dice do NOT enter `locked_order` on force-lock.

On `_resolve()`: populate `ThrowResult.shattered`, `pip_offsets`, `pip_multipliers`.

## ScoringEngine changes

In `score()`, filter `result.locked_order` to exclude shattered slots before scoring. Apply pip adjustments:
```gdscript
var raw_pip := result.faces[idx] + result.pip_offsets[idx]
pips += maxi(0, raw_pip) * result.pip_multipliers[idx]
```
Combo detection still uses raw `result.faces[idx]` (face value unchanged by materials).

## DiceBag.add()

```gdscript
func add(material: StringName, count: int = 1) -> void:
    for i in count:
        _dice.append(material)
```

## ShopScene changes

Extend `_MATERIAL_PATHS` constant (3 entries). Offer pool includes both charm offers and dice offers. The pool builds 3 offers total from a mixed pool; each offer card shows the die's material display_name, cost, and a description. Buying a die calls `RunCoordinator.bag.add(material_name)`.

Wait — `RunCoordinator` doesn't hold the `DiceBag`. The bag is created in `ThrowScene._ready()`. To make the bag persistent and accessible from the shop, it must move to `RunCoordinator`.

**DiceBag moves to RunCoordinator**: add `var bag: DiceBag` to RunCoordinator; initialize in `start_run()`. ThrowScene reads `RunCoordinator.bag` instead of creating its own.

## Tumble speed (Iron)

ThrowScene computes the effective tumble duration before calling `begin_tumble()`:
```gdscript
var tumble_s := _slowest_tumble_factor() * _config.tumble_duration_s
```

Where `_slowest_tumble_factor()` iterates the active tray's materials and returns the max `tumble_speed_factor` (reciprocal: Iron factor 1.4 means tumble is 1.4× longer).

Actually: rename it to `tumble_duration_factor` to avoid sign confusion. Iron: 1.4; Bone/Glass: 1.0.

**Amended during local verification (2026-10-05):** the factor originally reached only the animation, so with Iron the lock window opened at the base 1.5 s while the dice still tumbled for 2.1 s. `ThrowController.tumble_duration()` now owns the value (base × slowest drawn material's factor) and drives the Tumble/Reroll state timer. `ThrowScene._tumble_duration_s()` returns the same value for `begin_tumble()`, so the timer and the animation can't drift apart.
