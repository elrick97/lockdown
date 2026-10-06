extends GutTest
## Smoke Room dice renderer (dice-tumble spec): orientation, determinism, tap rects.

const TRAY := Vector2(1080.0, 1200.0)  # the throw scene's tray at base resolution
const DIE_MIN_PX := 126.0  # art-direction spec: die_min_px (48 dp)


func _tumbler_in_tray(materials: Array[StringName]) -> Viewport3DDiceTumbler:
	var tray := Control.new()
	tray.size = TRAY
	add_child_autofree(tray)
	var t := Viewport3DDiceTumbler.new()
	tray.add_child(t)
	var dice: Array[DiceBag.Die] = []
	for m in materials:
		dice.append(DiceBag.Die.new(m))
	t.build(dice)
	return t


func _faces(n: int) -> Array[int]:
	var out: Array[int] = []
	for i in n:
		out.append(1 + i % 6)
	return out


func _unlocked(n: int) -> Array[bool]:
	var out: Array[bool] = []
	out.resize(n)
	out.fill(false)
	return out


func test_every_face_lands_up_and_upright() -> void:
	for face in range(1, 7):
		var b := Viewport3DDiceTumbler.face_up_basis(face, 0.0)
		var normal: Vector3 = b * Viewport3DDiceTumbler.FACE_NORMAL[face]
		assert_lt(rad_to_deg(normal.angle_to(Vector3.UP)), 1.0, "face %d points up" % face)
		var tex_up: Vector3 = b * Viewport3DDiceTumbler.TEX_UP[face]
		assert_lt(rad_to_deg(tex_up.angle_to(Vector3.FORWARD)), 1.0, "face %d reads upright" % face)


func test_yaw_turns_about_the_vertical_only() -> void:
	var b := Viewport3DDiceTumbler.face_up_basis(4, deg_to_rad(10.0))
	assert_lt(rad_to_deg((b * Vector3.LEFT).angle_to(Vector3.UP)), 1.0, "still face 4 up after yaw")


func test_same_faces_same_settled_picture_and_rng_untouched() -> void:
	RunCoordinator.start_run(31337)
	var twin := RngCore.new(31337)
	var bases: Array = []
	for run in 2:
		var t := _tumbler_in_tray([&"standard", &"iron", &"glass", &"standard", &"standard", &"glass"])
		t.begin_tumble(_faces(6), _unlocked(6), 0.5)
		for step in 20:
			t.tick(0.05)
		var settled: Array[Basis] = []
		for n in t._dice_nodes:
			settled.append(n.basis)
		bases.append(settled)
	assert_eq(bases[0], bases[1], "identical settled orientations")
	assert_eq(RngService.randi_range(RngCore.STREAM_DICE, 1, 6), twin.randi_range(RngCore.STREAM_DICE, 1, 6),
		"the tumbles consumed no RNG")


func test_full_tray_tap_rects_meet_minimum_and_do_not_overlap() -> void:
	var mats: Array[StringName] = [&"standard", &"iron", &"glass", &"standard",
		&"glass", &"iron", &"standard", &"standard"]
	var t := _tumbler_in_tray(mats)
	t.reveal(_faces(8), _unlocked(8))
	await wait_frames(3)  # let the SubViewport take the tray's size
	var rects: Array[Rect2] = []
	for i in 8:
		var r := t.die_rect(i)
		assert_gte(r.size.x, DIE_MIN_PX, "die %d tap width %.0f px" % [i, r.size.x])
		assert_gte(r.size.y, DIE_MIN_PX, "die %d tap height %.0f px" % [i, r.size.y])
		rects.append(r)
	for i in 8:
		for j in range(i + 1, 8):
			assert_false(rects[i].intersects(rects[j]), "dice %d and %d don't overlap" % [i, j])


# --- add-lock-signifiers ---

func test_locked_die_seats_in_its_socket_with_a_padlock() -> void:
	var t := _tumbler_in_tray([&"standard", &"standard", &"standard"] as Array[StringName])
	t.reveal(_faces(3), _unlocked(3))
	var y0: float = t._dice_nodes[1].position.y
	t.lock_die(1, 2)
	assert_true(t.is_lock_seated(1), "socket and padlock shown")
	assert_almost_eq(t._dice_nodes[1].position.y, y0 + Viewport3DDiceTumbler.LOCK_LIFT, 0.001, "die lifts")
	assert_false(t.is_lock_seated(0), "unlocked die has no socket")
	assert_eq(t._mats[0].albedo_color, Viewport3DDiceTumbler.UNLOCKED_DIM, "unlocked dice dim while one is locked")
	assert_eq(t._mats[1].albedo_color, Color.WHITE, "the locked die stays bright")


func test_dead_die_is_cracked_dark_and_unseated() -> void:
	var t := _tumbler_in_tray([&"glass", &"standard"] as Array[StringName])
	t.reveal(_faces(2), _unlocked(2))
	t.mark_dead(0)
	assert_eq(t._mats[0].albedo_color, Viewport3DDiceTumbler.DEAD_TINT)
	assert_not_null(t._mats[0].next_pass, "crack overlay")
	assert_eq((t._mats[0].next_pass as StandardMaterial3D).albedo_texture.resource_path, "res://assets/dice/crack.png")
	assert_false(t.is_lock_seated(0), "dead dice never show a socket")
	assert_eq(t._mats[1].albedo_color, Color.WHITE, "no dimming when nothing is locked")
