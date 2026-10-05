extends GutTest
## DieAtlasCache: carved faces are stamped from carve tiles (dice-materials spec).

const BONE := preload("res://resources/dice_materials/bone.tres")
const GLASS := preload("res://resources/dice_materials/glass.tres")
const DIE_SCENE := preload("res://assets/dice/die.glb")
## In-game face layout after Blender Z-up → glTF Y-up (design D4).
const FACE_NORMALS := {
	1: Vector3.UP, 6: Vector3.DOWN, 3: Vector3.RIGHT, 4: Vector3.LEFT,
	2: Vector3.FORWARD, 5: Vector3.BACK,
}

var _cache: DieAtlasCache


func before_each() -> void:
	_cache = DieAtlasCache.new()


func _die_mesh() -> Mesh:
	var root := DIE_SCENE.instantiate()
	var mi := root.find_children("*", "MeshInstance3D", true, false)[0] as MeshInstance3D
	var mesh := mi.mesh
	root.free()
	return mesh


func test_tile_rects_match_the_mesh_uvs() -> void:
	# Every flat face's UVs must fall inside the tile the stamper writes for that face.
	var arrays := _die_mesh().surface_get_arrays(0)
	var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	var uvs: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
	var idx: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	var hits := {}
	for t in range(0, idx.size(), 3):
		# Flat faces carry hardened (face) normals; Godot winds front faces clockwise,
		# so the mesh normals are used rather than a cross product.
		var n := (normals[idx[t]] + normals[idx[t + 1]] + normals[idx[t + 2]]).normalized()
		for face: int in FACE_NORMALS:
			if n.dot(FACE_NORMALS[face]) > 0.999:
				var uv := (uvs[idx[t]] + uvs[idx[t + 1]] + uvs[idx[t + 2]]) / 3.0
				var px := Vector2(uv.x * 768.0, uv.y * 512.0)
				assert_true(Rect2(DieAtlasCache.tile_rect(face)).has_point(px),
					"face %d UV %s lies in its stamp tile %s" % [face, px, DieAtlasCache.tile_rect(face)])
				hits[face] = true
	assert_eq(hits.size(), 6, "found the flat triangles of all six faces")


func test_uncarved_die_shares_the_material_atlases() -> void:
	var tex := _cache.textures_for(BONE, &"", -1)
	assert_same(tex.albedo, BONE.albedo)
	assert_same(tex.orm, BONE.orm)


func test_wild_on_bone_six_replaces_only_that_tile() -> void:
	var tex := _cache.textures_for(BONE, &"wild", 6)
	var stamped: Image = (tex.albedo as Texture2D).get_image()
	stamped.clear_mipmaps()  # compare base levels; get_region keeps a mip chain
	stamped.convert(Image.FORMAT_RGBA8)
	var tile := (load("res://assets/dice/bone_wild_albedo.png") as Texture2D).get_image()
	tile.convert(Image.FORMAT_RGBA8)
	var base := BONE.albedo.get_image()
	base.clear_mipmaps()
	base.convert(Image.FORMAT_RGBA8)
	var r6 := DieAtlasCache.tile_rect(6)
	assert_eq(stamped.get_region(r6).get_data(), tile.get_data(), "face-6 tile is the Bone Wild tile")
	var r1 := DieAtlasCache.tile_rect(1)
	assert_eq(stamped.get_region(r1).get_data(), base.get_region(r1).get_data(), "face 1 untouched")


func test_glass_tile_keeps_its_alpha() -> void:
	var tex := _cache.textures_for(GLASS, &"spark", 3)
	var img: Image = (tex.albedo as Texture2D).get_image()
	img.convert(Image.FORMAT_RGBA8)
	var c := img.get_pixelv(DieAtlasCache.tile_rect(3).position + Vector2i(30, 128))
	assert_lt(c.a, 0.99, "Glass face background stays translucent after stamping")


func test_same_carving_reuses_the_stamped_atlas() -> void:
	var a := _cache.textures_for(BONE, &"wild", 6)
	var b := _cache.textures_for(BONE, &"wild", 6)
	assert_same(a.albedo, b.albedo, "cache hit returns the same texture")
	var c := _cache.textures_for(BONE, &"wild", 5)
	assert_ne(a.albedo, c.albedo, "a different face is a different variant")


func test_materials_resolve_by_gameplay_id() -> void:
	assert_eq(DiceMaterial.by_id(&"standard"), BONE, "the bag's built-in id maps to Bone")
	assert_eq(DiceMaterial.by_id(&"glass"), GLASS)
	assert_null(DiceMaterial.by_id(&"nope"))
