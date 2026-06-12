class_name DiceBag
extends RefCounted
## The run's bag of dice (dice-bag spec). All dice are identical standard d6
## for now; materials arrive in a later change. Draws consume only the seeded
## `bag` stream so bag randomness never shifts die-face outcomes.

const TRAY_CAP := 8
const STANDARD_DIE := &"standard"

var _dice: Array[StringName] = []


func _init(size: int) -> void:
	for i in size:
		_dice.append(STANDARD_DIE)


func available() -> int:
	return _dice.size()


## Draws up to `requested` dice without replacement, clamped to the tray cap
## and to what the bag still holds.
func draw(requested: int, rng: RngCore) -> Array[StringName]:
	var count := mini(mini(requested, TRAY_CAP), _dice.size())
	var drawn: Array[StringName] = []
	for i in count:
		var j := rng.randi_range(RngCore.STREAM_BAG, 0, _dice.size() - 1)
		drawn.append(_dice.pop_at(j) as StringName)
	return drawn


func return_dice(dice: Array[StringName]) -> void:
	_dice.append_array(dice)
