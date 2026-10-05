class_name TrinketInventory
extends RefCounted

const MAX_SLOTS := 2

var _trinkets: Array[Trinket] = []


func add_trinket(t: Trinket) -> bool:
	if _trinkets.size() >= MAX_SLOTS:
		return false
	_trinkets.append(t)
	return true


func consume(index: int) -> Trinket:
	if index < 0 or index >= _trinkets.size():
		return null
	return _trinkets.pop_at(index) as Trinket


func iter_trinkets() -> Array[Trinket]:
	return _trinkets.duplicate()


func is_full() -> bool:
	return _trinkets.size() >= MAX_SLOTS
