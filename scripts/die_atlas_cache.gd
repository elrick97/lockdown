class_name DieAtlasCache
extends RefCounted
## Presentation only: the atlas textures each die is drawn with. A carved die gets
## copies of its material's atlases with the carved face's tile replaced by that
## material's carve tile (dice-materials spec), cached per (material, carving,
## face). Atlases are imported lossless so their pixels can be read and stamped.

const TILE := 256
const DICE_DIR := "res://assets/dice/"
const MAPS: Array[String] = ["albedo", "normal", "orm"]

var _cache: Dictionary = {}  # "material|carve|face" -> {albedo, normal, orm: Texture2D}


## Pixel rect of face `face` in a 768×512 atlas (top-left image space). Faces 1–3
## sit on the bottom row, 4–6 on the top row, matching the die mesh's UVs.
static func tile_rect(face: int) -> Rect2i:
	@warning_ignore("integer_division")
	return Rect2i(((face - 1) % 3) * TILE, (1 - (face - 1) / 3) * TILE, TILE, TILE)


func textures_for(mat: DiceMaterial, carve_type: StringName, carved_face: int) -> Dictionary:
	if carve_type == &"" or carved_face < 1:
		return {"albedo": mat.albedo, "normal": mat.normal, "orm": mat.orm}
	# Carve tiles sit beside the material's atlas: bone_albedo.png → bone_wild_*.png
	# (the gameplay id can differ, e.g. Bone is &"standard").
	var prefix := mat.albedo.resource_path.get_file().trim_suffix("_albedo.png")
	var key := "%s|%s|%d" % [prefix, carve_type, carved_face]
	if _cache.has(key):
		return _cache[key]
	var out := {}
	for map_name in MAPS:
		var base: Texture2D = mat.get(map_name)
		var tile_path := "%s%s_%s_%s.png" % [DICE_DIR, prefix, carve_type, map_name]
		var tile: Texture2D = load(tile_path) if ResourceLoader.exists(tile_path) else null
		out[map_name] = _stamp(base, tile, carved_face) if base != null and tile != null else base
	_cache[key] = out
	return out


static func _stamp(base: Texture2D, tile: Texture2D, face: int) -> ImageTexture:
	var img := _rgba(base.get_image())
	img.blit_rect(_rgba(tile.get_image()), Rect2i(0, 0, TILE, TILE), tile_rect(face).position)
	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)


static func _rgba(img: Image) -> Image:
	if img.is_compressed():
		img.decompress()
	img.clear_mipmaps()
	img.convert(Image.FORMAT_RGBA8)
	return img
