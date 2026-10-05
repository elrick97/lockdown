class_name CharmInventory
extends RefCounted
## Ordered list of up to MAX_SLOTS active charms (charm-effect spec).
## Owned by RunCoordinator; reset on each start_run().

const MAX_SLOTS := 5

var _slots: Array[CharmEffect] = []


func add_charm(c: CharmEffect) -> bool:
	if is_full():
		return false
	_slots.append(c)
	return true


func iter_charms() -> Array[CharmEffect]:
	return _slots.duplicate()


func is_full() -> bool:
	return _slots.size() >= MAX_SLOTS


func size() -> int:
	return _slots.size()
