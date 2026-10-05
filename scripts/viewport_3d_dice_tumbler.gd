class_name Viewport3DDiceTumbler
extends DiceTumbler
## Spike B: 3D dice tumbling inside a SubViewport, composited into the 2D tray.
## Cubes are textured with procedurally generated pip faces (no binary assets),
## lit, and spun to rest over the tumble duration. Animation only — the faces
## are already decided by the RNG (dice-tumble spec).

const VIEW_RES := Vector2i(560, 620)  # SubViewport render resolution (recorded for the perf comparison)
const SCRAMBLE_UNTIL := 0.50
const SPACING := 1.55
const CUBE := 0.95

var _container: SubViewportContainer
var _subviewport: SubViewport
var _camera: Camera3D
var _dice: Array[Node3D] = []
var _mats: Array[StandardMaterial3D] = []
var _spin_axis: Array[Vector3] = []
var _face_tex := {}  # value:int -> ImageTexture
var _scramble_frame := 0


func _create_visuals(p_count: int) -> void:
	if _container != null:
		_container.queue_free()
	_dice.clear()
	_mats.clear()
	_spin_axis.clear()
	if _face_tex.is_empty():
		for v in range(1, 7):
			_face_tex[v] = _make_face_texture(v)

	_container = SubViewportContainer.new()
	_container.stretch = true
	_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_container)

	_subviewport = SubViewport.new()
	_subviewport.size = VIEW_RES
	_subviewport.transparent_bg = true
	_subviewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_container.add_child(_subviewport)

	@warning_ignore("integer_division")
	var rows := int(ceil(p_count / float(COLS)))
	_camera = Camera3D.new()
	_camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	_camera.size = rows * SPACING + 2.2
	_camera.position = Vector3(0.0, 0.0, 8.0)
	_subviewport.add_child(_camera)

	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-48.0, -34.0, 0.0)
	_subviewport.add_child(light)
	var fill := DirectionalLight3D.new()
	fill.light_energy = 0.4
	fill.rotation_degrees = Vector3(40.0, 130.0, 0.0)
	_subviewport.add_child(fill)

	var quad := QuadMesh.new()
	quad.size = Vector2(CUBE, CUBE)
	# A cube of 6 textured quads (BoxMesh UVs don't show a full texture per face).
	# All faces share one material so the whole die reads as the current value.
	var faces6 := [
		Transform3D(Basis(), Vector3(0, 0, CUBE / 2.0)),                                  # +Z
		Transform3D(Basis(Vector3.UP, PI), Vector3(0, 0, -CUBE / 2.0)),                   # -Z
		Transform3D(Basis(Vector3.UP, PI / 2.0), Vector3(CUBE / 2.0, 0, 0)),             # +X
		Transform3D(Basis(Vector3.UP, -PI / 2.0), Vector3(-CUBE / 2.0, 0, 0)),           # -X
		Transform3D(Basis(Vector3.RIGHT, -PI / 2.0), Vector3(0, CUBE / 2.0, 0)),         # +Y
		Transform3D(Basis(Vector3.RIGHT, PI / 2.0), Vector3(0, -CUBE / 2.0, 0)),         # -Y
	]
	for i in p_count:
		var mat := StandardMaterial3D.new()
		mat.albedo_texture = _face_tex[1]
		var die := Node3D.new()
		die.position = _world_pos(i, rows)
		for xform in faces6:
			var face := MeshInstance3D.new()
			face.mesh = quad
			face.material_override = mat
			face.transform = xform
			die.add_child(face)
		_subviewport.add_child(die)
		_dice.append(die)
		_mats.append(mat)
		# Deterministic per-die spin axis (never the gameplay RNG).
		_spin_axis.append(Vector3(0.6 + 0.3 * (i % 2), 1.0, 0.4 + 0.2 * (i % 3)).normalized())


func _world_pos(index: int, rows: int) -> Vector3:
	var col := index % COLS
	@warning_ignore("integer_division")
	var row := index / COLS
	var x := (col - (COLS - 1) / 2.0) * SPACING
	var y := ((rows - 1) / 2.0 - row) * SPACING
	return Vector3(x, y, 0.0)


func _render_tumbling(progress: float) -> void:
	_scramble_frame += 1
	var eased := 1.0 - pow(1.0 - progress, 3.0)
	for i in count:
		if locked[i]:
			continue
		if progress < SCRAMBLE_UNTIL:
			_set_texture(i, 1 + (_scramble_frame / 2 + i) % 6)
		else:
			_set_texture(i, faces[i])
		var angle := (1.0 - eased) * 3.0 * TAU
		_dice[i].basis = Basis(_spin_axis[i], angle)


func _render_face(index: int, face: int, is_locked: bool) -> void:
	if index < 0 or index >= _dice.size():
		return
	_set_texture(index, face)
	_mats[index].albedo_color = COLOR_LOCKED if is_locked else Color.WHITE
	_dice[index].basis = Basis()


func flash_die(index: int, color: Color, duration: float) -> void:
	if index < 0 or index >= _mats.size():
		return
	var t := create_tween()
	t.tween_property(_mats[index], "albedo_color", color, duration * 0.5)
	t.tween_property(_mats[index], "albedo_color", COLOR_LOCKED, duration * 0.5)


func _set_texture(index: int, value: int) -> void:
	if index >= 0 and index < _mats.size():
		_mats[index].albedo_texture = _face_tex[clampi(value, 1, 6)]


## Build a pip-face albedo texture for `value` (reuses the 2D pip layout).
func _make_face_texture(value: int) -> ImageTexture:
	var s := 128
	var img := Image.create(s, s, false, Image.FORMAT_RGBA8)
	img.fill(COLOR_FACE)
	var pip_r := int(s * 0.085)
	for key in FACE_PIPS[value]:
		var n: Vector2 = PIP[key]
		_draw_disc(img, Vector2(n.x * s, n.y * s), pip_r)
	return ImageTexture.create_from_image(img)


func _draw_disc(img: Image, center: Vector2, r: int) -> void:
	var x0 := maxi(0, int(center.x - r))
	var x1 := mini(img.get_width() - 1, int(center.x + r))
	var y0 := maxi(0, int(center.y - r))
	var y1 := mini(img.get_height() - 1, int(center.y + r))
	for y in range(y0, y1 + 1):
		for x in range(x0, x1 + 1):
			if Vector2(x, y).distance_to(center) <= r:
				img.set_pixel(x, y, COLOR_PIP)
