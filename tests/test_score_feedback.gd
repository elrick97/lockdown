extends GutTest
## add-score-feedback scene wiring: live Heat during windows, timer urgency, the
## score HUD sits above the table, and THROW stays disabled until the cascade ends.

const THROW_SCENE := preload("res://scenes/throw/throw_scene.tscn")


func _scene() -> Control:
	RunCoordinator.new_run(5)
	var scene: Control = THROW_SCENE.instantiate()
	add_child_autofree(scene)
	scene.ante_cleared.disconnect(RunCoordinator.on_ante_cleared)
	scene.set_process(false)  # the test drives the controller clock
	return scene


func _open_window(scene: Control) -> void:
	scene._on_throw_pressed()
	scene._controller.tick(scene._controller.tumble_duration() + 0.01)
	assert_eq(scene._controller.state, ThrowController.State.LOCK_WINDOW)


func test_live_heat_is_what_locking_now_would_give() -> void:
	var scene := _scene()
	_open_window(scene)
	var w: float = scene._effective_window_s
	scene._controller.tick(0.5)
	var projected: Array[float] = scene._controller.projected_window_remaining()
	assert_almost_eq(projected[0], w - 0.5, 0.02)
	assert_almost_eq(projected[1], w, 0.001)
	assert_almost_eq(projected[2], w, 0.001)
	scene._update_visuals()
	var expected := Heat.from_remaining(projected, scene._scoring_config, w)
	assert_eq(scene._hud.heat_label.text, "×%.2f" % expected, "HEAT plaque shows the live value")


func test_timer_turns_urgent_in_the_last_stretch() -> void:
	var scene := _scene()
	_open_window(scene)
	scene._update_visuals()
	assert_eq(scene._timer_fill.modulate, Color.WHITE, "calm while time is left")
	scene._controller.tick(scene._effective_window_s - scene._fx.urgency_s * 0.25)
	scene._update_visuals()
	assert_ne(scene._timer_fill.modulate, Color.WHITE, "tinted in the last urgency_s")
	assert_gt(scene._timer_fill.modulate.r, scene._timer_fill.modulate.g, "toward oxblood")


func test_hud_draws_above_the_table_and_below_the_end_panel() -> void:
	var scene := _scene()
	assert_gt(scene._hud.get_index(), scene._tray.get_index())
	assert_lt(scene._hud.get_index(), scene._end_panel.get_index())
	assert_eq(scene._hud.mouse_filter, Control.MOUSE_FILTER_IGNORE, "HUD never eats taps")


func test_throw_disabled_until_cascade_finishes() -> void:
	var scene := _scene()
	scene._round.target = 1000000  # keep the round open whatever this throw scores
	_open_window(scene)
	for i in scene._controller.faces.size():
		scene._controller.lock_die(i)
	assert_eq(scene._controller.state, ThrowController.State.RESOLVED)
	assert_true(scene._throw_button.disabled, "disabled while the cascade plays")
	scene._cascade.skip()
	assert_false(scene._throw_button.disabled, "re-enabled when it finishes")
