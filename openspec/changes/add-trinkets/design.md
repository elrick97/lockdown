# Design: add-trinkets

## Trinket resource

```gdscript
class_name Trinket
extends Resource
@export var display_name: String
@export var description: String
@export var cost: int
```

Each trinket type is a GDScript subclass with a single method:
```gdscript
func activate(controller: ThrowController) -> void
```

Trinket subclasses:
- `TrinketReTumble.activate()`: calls `controller.force_reroll_unlocked()`
- `TrinketFreezeTimer.activate()`: calls `controller.freeze_window(2.0)`

## TrinketInventory

```gdscript
class_name TrinketInventory
extends RefCounted
const MAX_SLOTS := 2
var _trinkets: Array[Trinket]
func add_trinket(t: Trinket) -> bool   # false if full
func iter_trinkets() -> Array[Trinket]
func consume(index: int) -> Trinket    # removes and returns
func is_full() -> bool
```

Owned by RunCoordinator, reset in `start_run()`.

## ThrowController additions

```gdscript
func force_reroll_unlocked() -> void
    # Re-rolls all unlocked dice immediately (same as between-window reroll).
    # No-op outside LOCK_WINDOW state.

func freeze_window(duration: float) -> void
    # Subtracts `duration` from _accumulated, effectively extending the window.
    # Clamped so _accumulated never goes below 0.
```

## ThrowScene additions

Two trinket buttons shown bottom-centre during LOCK_WINDOW state, hidden otherwise.
Buttons are dynamically built from `RunCoordinator.trinket_inventory.iter_trinkets()`.
On press: call `trinket.activate(_controller)` then mark trinket consumed.

Layout: a HBoxContainer below the timer bar, with up to 2 trinket buttons.

## ShopScene additions

Add trinket paths to the offer pool. `_TRINKET_PATHS: Array[String]` with 2 entries.
Buying a trinket: `RunCoordinator.trinket_inventory.add_trinket(trinket)`.
