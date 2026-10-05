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
