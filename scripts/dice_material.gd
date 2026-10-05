class_name DiceMaterial
extends Resource

const DIR := "res://resources/dice_materials/"

static var _by_id: Dictionary = {}

@export var material_id: StringName = &""
@export var display_name: String = ""
@export var description: String = ""
@export var pip_offset: int = 0
@export var pip_multiplier: int = 1
@export var shatter_on_reroll: bool = false
@export var tumble_duration_factor: float = 1.0
@export var cost: int = 0

## The material whose `material_id` is `id` (e.g. &"standard" → bone.tres), or null.
## Indexes the materials folder once; list_directory also sees exported remaps.
static func by_id(id: StringName) -> DiceMaterial:
	if _by_id.is_empty():
		for file in ResourceLoader.list_directory(DIR):
			if file.ends_with(".tres") or file.ends_with(".res"):
				var mat := load(DIR + file) as DiceMaterial
				if mat != null:
					_by_id[mat.material_id] = mat
	return _by_id.get(id)


@export_group("Visuals")
## Six-face atlases (768×512, standard face layout; dice-materials spec). The
## renderer builds each die's look from these fields only, so a new material is
## a .tres plus textures. Carve tiles live beside them by naming convention:
## res://assets/dice/<material_id>_<carve>_{albedo,normal,orm}.png
@export var albedo: Texture2D
@export var normal: Texture2D
@export var orm: Texture2D
## Faked Glass (art-direction spec): alpha from albedo, fresnel rim, no refraction.
@export var transparent: bool = false
@export_range(0.0, 1.0) var rim: float = 0.0
