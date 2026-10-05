extends SceneTree
## Renders each art-direction .glb in this project's GL Compatibility renderer and
## saves a PNG next to the style frames (OpenSpec change add-art-direction, D9).
## Local desktop check only, run from the repo root:
##   godot_console --path . --rendering-driver opengl3 -s tools/art_preview.gd

const GLB_DIR := "res://assets/art_direction/gltf/"
const OUT_DIR := "res://assets/art_direction/gltf/preview/"
const VIEW_SIZE := Vector2i(1100, 300)
const PX_PER_UNIT := 126.0  # 48 dp at base resolution (art-direction spec: die_min_px)
const TILT_DEG := 18.0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	for file in DirAccess.get_files_at(GLB_DIR):
		if file.get_extension() == "glb":
			await _render(file)
	quit()


func _render(file: String) -> void:
	var vp := SubViewport.new()
	vp.size = VIEW_SIZE
	vp.own_world_3d = true
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(vp)

	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.06, 0.06, 0.07)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.4, 0.4, 0.45)
	var world_env := WorldEnvironment.new()
	world_env.environment = env
	vp.add_child(world_env)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55.0, -30.0, 0.0)
	sun.light_energy = 1.2
	sun.shadow_enabled = true
	vp.add_child(sun)

	var floor_mesh := PlaneMesh.new()
	floor_mesh.size = Vector2(14.0, 6.0)
	var floor_mat := StandardMaterial3D.new()
	floor_mat.albedo_color = Color(0.16, 0.17, 0.18)
	floor_mat.roughness = 0.95
	floor_mesh.material = floor_mat
	var floor_node := MeshInstance3D.new()
	floor_node.mesh = floor_mesh
	vp.add_child(floor_node)

	var dice := (load(GLB_DIR + file) as PackedScene).instantiate()
	vp.add_child(dice)

	# Same view as the frames: orthographic, 18° off top-down, looking from +Z (Blender -Y).
	var cam := Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.size = VIEW_SIZE.y / PX_PER_UNIT
	cam.rotation_degrees = Vector3(-(90.0 - TILT_DEG), 0.0, 0.0)
	var forward := -cam.transform.basis.z
	cam.position = Vector3(0.0, 0.5, 0.0) - forward * 20.0
	vp.add_child(cam)

	for i in 4:
		await process_frame
	var out_path := OUT_DIR + file.get_basename() + "_godot.png"
	vp.get_texture().get_image().save_png(out_path)
	print("saved ", out_path)
	vp.queue_free()
	await process_frame
