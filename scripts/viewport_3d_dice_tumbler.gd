class_name Viewport3DDiceTumbler
extends DiceTumbler
## Smoke Room dice (add-smoke-room-dice): six-face atlas dice in a SubViewport,
## composited over the tray. Each die tumbles to the orientation that puts its
## predetermined face up, then settles with a small slot-derived yaw. Animation
## only: nothing here reads the RNG (dice-tumble spec).

const TILT_DEG := 18.0  # art-direction spec: camera_tilt_deg
const SPACING := 1.6  # world units between die centres (die = 1 unit)
const MARGIN := 1.0  # world units of air around the grid
const SPIN_TURNS := 3.0
const DEAD_TINT := Color(0.38, 0.38, 0.38)
## Lock signifiers (add-lock-signifiers): a locked die rises into a brass socket and
## wears a padlock; while any die is locked the unlocked ones dim (figure/ground).
const LOCK_LIFT := 0.12
const UNLOCKED_DIM := Color(0.88, 0.88, 0.88)
const SOCKET_SIZE := 1.6
const PADLOCK_OFFSET := Vector3(0.46, 0.62, 0.46)  # front-right top corner, over the die
const PADLOCK_PX := 0.0032  # world units per texel: 128 px ≈ 0.41 units
const GLASS_GLOW := 0.35
const KEY_LIGHT := Color("#FFDBA8")  # art-direction spec: lamp_pool key
const DIE_SCENE := preload("res://assets/dice/die.glb")
const SOCKET_TEX := preload("res://assets/dice/lock_socket.png")
const PADLOCK_TEX := preload("res://assets/dice/padlock.png")
const CRACK_TEX := preload("res://assets/dice/crack.png")
const BLOB_TEX := preload("res://assets/dice/blob_shadow.png")
## In-game face normals: Blender Z-up exported to glTF Y-up (design D4).
const FACE_NORMAL := {
	1: Vector3.UP, 6: Vector3.DOWN, 3: Vector3.RIGHT, 4: Vector3.LEFT,
	2: Vector3.FORWARD, 5: Vector3.BACK,
}
## Each face tile's "up" (Blender +V) in mesh space, so a settled face reads upright.
const TEX_UP := {
	1: Vector3.FORWARD, 6: Vector3.BACK, 3: Vector3.UP, 4: Vector3.UP,
	2: Vector3.UP, 5: Vector3.UP,
}
## Small fixed per-slot yaw so a settled tray doesn't look gridded (never the RNG).
const SLOT_YAW_DEG: Array[float] = [-8.0, 6.0, -4.0, 10.0, -10.0, 4.0, 7.0, -6.0]

static var _die_mesh: Mesh

var _atlas := DieAtlasCache.new()
var _container: SubViewportContainer
var _subviewport: SubViewport
var _camera: Camera3D
var _dice_nodes: Array[Node3D] = []
var _mats: Array[ORMMaterial3D] = []
var _rings: Array[MeshInstance3D] = []
var _padlocks: Array[Sprite3D] = []
var _ground: Array[Vector3] = []
static var _crack_mat: StandardMaterial3D
var _spin_axis: Array[Vector3] = []


## Orientation that puts `face` on top, upright to the camera, turned by `yaw_rad`.
static func face_up_basis(face: int, yaw_rad: float) -> Basis:
	var to_top := _face_to_top(face)
	var tex_up: Vector3 = to_top * TEX_UP[face]
	var upright := tex_up.signed_angle_to(Vector3.FORWARD, Vector3.UP)
	return Basis(Vector3.UP, upright + yaw_rad) * to_top


static func _face_to_top(face: int) -> Basis:
	match face:
		6:
			return Basis(Vector3.RIGHT, PI)
		3:
			return Basis(Vector3.BACK, PI / 2.0)
		4:
			return Basis(Vector3.BACK, -PI / 2.0)
		2:
			return Basis(Vector3.RIGHT, PI / 2.0)
		5:
			return Basis(Vector3.RIGHT, -PI / 2.0)
	return Basis()


static func slot_yaw(index: int) -> float:
	return deg_to_rad(SLOT_YAW_DEG[index % SLOT_YAW_DEG.size()])


static func _cols_for(n: int) -> int:
	return 3 if n <= 6 else 4


func _create_visuals(p_count: int) -> void:
	if _container != null:
		_container.queue_free()
	_dice_nodes.clear()
	_mats.clear()
	_rings.clear()
	_padlocks.clear()
	_ground.clear()
	_spin_axis.clear()
	if _die_mesh == null:
		_die_mesh = _extract_mesh()

	_container = SubViewportContainer.new()
	_container.stretch = true  # SubViewport matches the tray: full resolution, crisp dice
	_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_container)
	_subviewport = SubViewport.new()
	_subviewport.transparent_bg = true
	_subviewport.own_world_3d = true
	_subviewport.msaa_3d = Viewport.MSAA_2X
	_subviewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_container.add_child(_subviewport)

	var cols := _cols_for(p_count)
	@warning_ignore("integer_division")
	var rows := (p_count + cols - 1) / cols
	_camera = Camera3D.new()
	_camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	_camera.keep_aspect = Camera3D.KEEP_WIDTH
	_camera.size = (cols - 1) * SPACING + 1.0 + 2.0 * MARGIN
	_camera.rotation_degrees = Vector3(-(90.0 - TILT_DEG), 0.0, 0.0)
	_camera.position = Vector3(0.0, 0.5, 0.0) + _camera.transform.basis.z * 30.0
	_subviewport.add_child(_camera)

	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-62.0, -28.0, 0.0)
	light.light_color = KEY_LIGHT
	light.light_energy = 1.15
	_subviewport.add_child(light)
	var env := Environment.new()
	env.background_mode = Environment.BG_CLEAR_COLOR
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.55, 0.5, 0.47)
	env.ambient_light_energy = 0.75
	var world_env := WorldEnvironment.new()
	world_env.environment = env
	_subviewport.add_child(world_env)

	for i in p_count:
		@warning_ignore("integer_division")
		var row := i / cols
		var col := i % cols
		var ground := Vector3((col - (cols - 1) / 2.0) * SPACING, 0.0, (row - (rows - 1) / 2.0) * SPACING)
		_subviewport.add_child(_floor_quad(ground + Vector3(0, 0.001, 0), 1.5, BLOB_TEX, Color.WHITE, true))
		var ring := _floor_quad(ground + Vector3(0, 0.002, 0), SOCKET_SIZE, SOCKET_TEX, Color.WHITE, false)
		_subviewport.add_child(ring)
		_rings.append(ring)
		var padlock := Sprite3D.new()
		padlock.texture = PADLOCK_TEX
		padlock.pixel_size = PADLOCK_PX
		padlock.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		padlock.shaded = false
		padlock.no_depth_test = true
		padlock.render_priority = 1
		padlock.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		padlock.position = ground + Vector3(0.0, 0.5 + LOCK_LIFT, 0.0) + PADLOCK_OFFSET
		padlock.visible = false
		_subviewport.add_child(padlock)
		_padlocks.append(padlock)
		_ground.append(ground)
		var mat := _material_for(dice[i] if i < dice.size() else null)
		var die := MeshInstance3D.new()
		die.mesh = _die_mesh
		die.material_override = mat
		die.position = ground + Vector3(0.0, 0.5, 0.0)
		die.basis = face_up_basis(1, slot_yaw(i))
		_subviewport.add_child(die)
		_dice_nodes.append(die)
		_mats.append(mat)
		# Deterministic per-die spin axis (never the gameplay RNG).
		_spin_axis.append(Vector3(0.6 + 0.3 * (i % 2), 1.0, 0.4 + 0.2 * (i % 3)).normalized())


func _material_for(die: DiceBag.Die) -> ORMMaterial3D:
	var m := ORMMaterial3D.new()
	var dm := DiceMaterial.by_id(die.material_id) if die != null else null
	if dm == null or dm.albedo == null:
		return m
	var tex := _atlas.textures_for(dm, die.carve_type, die.carved_face)
	m.albedo_texture = tex.albedo
	m.normal_enabled = true
	m.normal_texture = tex.normal
	m.orm_texture = tex.orm
	m.roughness = 1.0  # texture values used as-is
	m.metallic = 1.0
	if dm.transparent:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		# Faked Glass (art-direction spec): a faint inner glow from its own albedo.
		m.emission_enabled = true
		m.emission_texture = tex.albedo
		m.emission_energy_multiplier = GLASS_GLOW
	if dm.rim > 0.0:
		m.rim_enabled = true
		m.rim = dm.rim
		m.rim_tint = 0.6
	return m


func _floor_quad(pos: Vector3, size: float, tex: Texture2D, tint: Color, shown: bool) -> MeshInstance3D:
	var quad := PlaneMesh.new()
	quad.size = Vector2(size, size)
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.albedo_texture = tex
	m.albedo_color = tint
	quad.material = m
	var mi := MeshInstance3D.new()
	mi.mesh = quad
	mi.position = pos
	mi.visible = shown
	return mi


static func _extract_mesh() -> Mesh:
	var root := DIE_SCENE.instantiate()
	var mi := root.find_children("*", "MeshInstance3D", true, false)[0] as MeshInstance3D
	var mesh := mi.mesh
	root.free()
	return mesh


func _render_tumbling(progress: float) -> void:
	var eased := 1.0 - pow(1.0 - progress, 3.0)
	for i in count:
		if is_static(i):
			continue
		var angle := (1.0 - eased) * SPIN_TURNS * TAU
		_dice_nodes[i].basis = face_up_basis(faces[i], slot_yaw(i)) * Basis(_spin_axis[i], angle)


func _render_face(index: int, face: int, is_locked: bool) -> void:
	if index < 0 or index >= _dice_nodes.size():
		return
	var seated := is_locked and not dead[index]
	_dice_nodes[index].basis = face_up_basis(face, slot_yaw(index))
	_dice_nodes[index].position.y = 0.5 + (LOCK_LIFT if seated else 0.0)
	_rings[index].visible = seated
	_padlocks[index].visible = seated
	if dead[index] and _mats[index].next_pass == null:
		_mats[index].next_pass = _crack_material()
	_refresh_tints()


## Every die's resting tint: dead dice dark and cracked; while any die is locked,
## the unlocked ones dim so the locked set stands out.
func _refresh_tints() -> void:
	for i in _mats.size():
		_mats[i].albedo_color = _resting_tint(i)


func _resting_tint(index: int) -> Color:
	if dead[index]:
		return DEAD_TINT
	if not locked[index] and _any_seated():
		return UNLOCKED_DIM
	return Color.WHITE


func _any_seated() -> bool:
	for i in locked.size():
		if locked[i] and not dead[i]:
			return true
	return false


func is_lock_seated(index: int) -> bool:
	return index >= 0 and index < _padlocks.size() and _padlocks[index].visible and _rings[index].visible


## Crack overlay for shattered Glass: triplanar so it wraps the die, drawn as a pass
## over the die's own material.
static func _crack_material() -> StandardMaterial3D:
	if _crack_mat == null:
		_crack_mat = StandardMaterial3D.new()
		_crack_mat.albedo_texture = CRACK_TEX
		_crack_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_crack_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_crack_mat.uv1_triplanar = true
		_crack_mat.uv1_scale = Vector3(1.0, 1.0, 1.0)
		_crack_mat.grow = true
		_crack_mat.grow_amount = 0.004
		_crack_mat.render_priority = 1
	return _crack_mat


func flash_die(index: int, color: Color, duration: float) -> void:
	if index < 0 or index >= _mats.size():
		return
	var t := create_tween()
	t.tween_property(_mats[index], "albedo_color", color, duration * 0.5)
	t.tween_property(_mats[index], "albedo_color", _resting_tint(index), duration * 0.5)


func deny_die(index: int) -> void:
	if index < 0 or index >= _dice_nodes.size():
		return
	var node := _dice_nodes[index]
	# Remember the resting spot once, so repeated taps mid-wiggle never drift the die.
	var home: Vector3 = node.get_meta(&"deny_home", node.position)
	node.set_meta(&"deny_home", home)
	var t := create_tween()
	for dx: float in [0.08, -0.07, 0.05, -0.03, 0.0]:
		t.tween_property(node, "position:x", home.x + dx, 0.035)


func punch_die(index: int, amount: float, duration: float) -> void:
	if index < 0 or index >= _dice_nodes.size():
		return
	var node := _dice_nodes[index]
	var t := create_tween()
	t.tween_property(node, "scale", Vector3.ONE * amount, duration * 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(node, "scale", Vector3.ONE, duration * 0.65).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


## Bounds of the die's projected mesh in global canvas coordinates (dice-tumble spec).
func die_rect(index: int) -> Rect2:
	if _camera == null or index < 0 or index >= _dice_nodes.size() or _subviewport.size == Vector2i.ZERO:
		return Rect2()
	var xf := _dice_nodes[index].global_transform
	var box := _die_mesh.get_aabb()
	var to_canvas := _container.size / Vector2(_subviewport.size)
	var r := Rect2()
	for c in 8:
		var corner := box.position + box.size * Vector3(c & 1, (c >> 1) & 1, (c >> 2) & 1)
		var p := _camera.unproject_position(xf * corner) * to_canvas
		r = Rect2(p, Vector2.ZERO) if c == 0 else r.expand(p)
	r.position += _container.global_position
	return r
