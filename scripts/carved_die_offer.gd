class_name CarvedDieOffer
extends Resource
## Shop-offer resource for a pre-carved die (carving spec).
## Buying one calls DiceBag.add_carved(material_id, carved_face, carve_type).

@export var display_name: String = ""
@export var description: String = ""
@export var cost: int = 0
## Shop card icon (add-shop-icons).
@export var icon: Texture2D
@export var material_id: StringName = &"standard"
@export var carved_face: int = 6
@export var carve_type: StringName = &"gem"
