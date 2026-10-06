class_name DiceBag
extends RefCounted
## The run's bag of dice (dice-bag spec). Each die carries a material and an
## optional single-face carving (carved_face ≥ 0, carve_type non-empty).

const TRAY_CAP := 8
const STANDARD_MAT := &"standard"

class Die:
	var material_id: StringName
	var carved_face: int  # -1 = uncarved
	var carve_type: StringName  # &"" = none; &"wild", &"gem", &"spark"

	func _init(mat: StringName, face: int = -1, carve: StringName = &"") -> void:
		material_id = mat
		carved_face = face
		carve_type = carve


var _dice: Array[Die] = []


func _init(size: int) -> void:
	for i in size:
		_dice.append(Die.new(STANDARD_MAT))


func available() -> int:
	return _dice.size()


## Draws up to `requested` dice without replacement, clamped to the tray cap
## and to what the bag still holds.
func draw(requested: int, rng: RngCore) -> Array[Die]:
	var count := mini(mini(requested, TRAY_CAP), _dice.size())
	var drawn: Array[Die] = []
	for i in count:
		var j := rng.randi_range(RngCore.STREAM_BAG, 0, _dice.size() - 1)
		drawn.append(_dice.pop_at(j) as Die)
	return drawn


func return_dice(dice: Array[Die]) -> void:
	_dice.append_array(dice)


## What the bag holds, for display: "6 Bone · 1 Glass · 1 Gem 5" (shop-scene spec).
## Read-only; order is first appearance in the bag.
func summary() -> String:
	var order: Array[String] = []
	var counts := {}
	for d in _dice:
		var label: String
		if d.carve_type != &"":
			label = "%s %d" % [String(d.carve_type).capitalize(), d.carved_face]
		else:
			var mat := DiceMaterial.by_id(d.material_id)
			label = mat.display_name if mat != null else String(d.material_id)
		if not counts.has(label):
			counts[label] = 0
			order.append(label)
		counts[label] += 1
	var parts: Array[String] = []
	for label in order:
		parts.append("%d %s" % [counts[label], label])
	return "  ·  ".join(parts)


func add(material: StringName, count: int = 1) -> void:
	for i in count:
		_dice.append(Die.new(material))


func add_carved(material: StringName, carved_face: int, carve_type: StringName,
		count: int = 1) -> void:
	for i in count:
		_dice.append(Die.new(material, carved_face, carve_type))
