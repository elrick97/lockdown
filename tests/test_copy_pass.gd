extends GutTest
## copy-terminology-pass: item text matches the rule maths, status copy reports
## progress, and captions are readable on a phone (≥ 30 px).


func _result(faces: Array, windows: Array) -> ThrowResult:
	var r := ThrowResult.new()
	for i in faces.size():
		r.faces.append(int(faces[i]))
		r.locked_order.append(i)
		r.lock_windows.append(int(windows[i]))
	return r


func _score(charm: CharmEffect, faces: Array, windows: Array) -> ScoreBreakdown:
	var inv := CharmInventory.new()
	inv.add_charm(charm)
	return ScoringEngine.new().score(_result(faces, windows), ScoringConfig.new(), 2.5, false, inv)


func test_quick_draw_text_matches_its_plus_two() -> void:
	var qd: CharmEffect = load("res://resources/charms/quick_draw.tres")
	assert_true(qd.description.contains("+2 Mult"), qd.description)
	assert_almost_eq(_score(qd, [4, 4], [1, 1]).charm_mult, 2.0, 0.001)


func test_ice_cold_text_matches_lock_nothing_in_window_one() -> void:
	var ic: CharmEffect = load("res://resources/charms/ice_cold.tres")
	assert_true(ic.description.begins_with("Lock nothing in Window 1"), ic.description)
	assert_almost_eq(_score(ic, [4, 4], [2, 3]).charm_mult, 3.0, 0.001)
	assert_almost_eq(_score(ic, [4, 4], [1, 3]).charm_mult, 0.0, 0.001)


func test_snake_charmer_text_states_the_trade() -> void:
	var sc: CharmEffect = load("res://resources/charms/snake_charmer.tres")
	assert_true(sc.description.contains("4 Mult") and sc.description.contains("no Pair chips"), sc.description)
	var bd := _score(sc, [1, 1], [1, 1])
	assert_eq(bd.combo_mult, 4)
	assert_eq(bd.bonus_chips, 0)


func test_freeze_timer_text_says_plus_two_seconds() -> void:
	assert_eq(load("res://resources/trinkets/freeze_timer.tres").description, "+2 s on the current lock window.")


func test_no_ascii_x_multipliers_in_item_text() -> void:
	for dir in ["res://resources/charms/", "res://resources/dice_materials/", "res://resources/trinkets/"]:
		for f in DirAccess.get_files_at(dir):
			if f.ends_with(".tres"):
				var d: String = load(dir + f).get("description")
				var ascii_x := false
				for i in d.length() - 1:
					if d[i] == "x" and d[i + 1].is_valid_int() and (i == 0 or d[i - 1] == " "):
						ascii_x = true
				assert_false(ascii_x, "%s uses × not x" % f)


func test_status_after_a_throw_reports_progress() -> void:
	var s := load("res://scenes/throw/throw_scene.gd")
	assert_eq(s.status_after_throw(120, 230, 2), "120 scored · 230 to go · 2 throws left")
	assert_eq(s.status_after_throw(120, 90, 1), "LAST THROW · NEED 90")
	assert_eq(s.status_after_throw(300, 0, 1), "Target hit!")


func test_plaque_captions_are_readable() -> void:
	var hud := ScoreHud.new()
	add_child_autofree(hud)
	for plaque in [hud._chips_plaque, hud._mult_plaque, hud._heat_plaque]:
		var caption := plaque.get_child(0) as Label
		assert_gte(caption.get_theme_font_size("font_size"), 30, "%s caption ≥ 30 px" % caption.text)
	assert_eq(UiStyle.MUTED, Color("#A8977C"))
