class_name DiceMaterial
extends Resource

const DIR := "res://resources/dice_materials/"

static var _path_by_id: Dictionary = {}  # material_id -> resource path (no strong refs)

@export var material_id: StringName = &""
@export var display_name: String = ""
@export var description: String = ""
@export var pip_offset: int = 0
@export var pip_multiplier: int = 1
@export var shatter_on_reroll: bool = false
@export var tumble_duration_factor: float = 1.0
@export var cost: int = 0
## Shop card icon (add-shop-icons); null for dice that are never sold.
@export var icon: Texture2D

## The material whose `material_id` is `id` (e.g. &"standard" → bone.tres), or null.
## Indexes the materials folder once; list_directory also sees exported remaps. Only
## paths are kept, and lookups go through the resource cache, so this static index
## never outlives the renderer with textures still referenced.
static func by_id(id: StringName) -> DiceMaterial:
	if _path_by_id.is_empty():
		for file in ResourceLoader.list_directory(DIR):
			if file.ends_with(".tres") or file.ends_with(".res"):
				var mat := load(DIR + file) as DiceMaterial
				if mat != null:
					_path_by_id[mat.material_id] = DIR + file
	return load(_path_by_id[id]) as DiceMaterial if _path_by_id.has(id) else null


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
