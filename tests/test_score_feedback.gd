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


func _tap(scene: Control) -> void:
	var ev := InputEventMouseButton.new()
	ev.button_index = MOUSE_BUTTON_LEFT
	ev.pressed = true
	ev.position = Vector2(540, 1100)
	scene._gui_input(ev)


func _resolve_all(scene: Control) -> void:
	scene._round.target = 1000000
	_open_window(scene)
	for i in scene._controller.faces.size():
		scene._controller.lock_die(i)
	assert_true(scene._cascade.is_playing())


func test_tap_skips_the_cascade_after_the_grace() -> void:
	var scene := _scene()
	_resolve_all(scene)
	assert_true(scene._skip_hint.visible, "TAP TO SKIP shown while the score builds")
	_tap(scene)
	assert_true(scene._cascade.is_playing(), "a tap inside the grace does not skip")
	scene._cascade._started_ms -= int(scene._fx.skip_grace_s * 1000.0) + 50
	_tap(scene)
	assert_false(scene._cascade.is_playing(), "a later tap skips to the end")
	assert_false(scene._throw_button.disabled, "THROW is back right away")
	assert_false(scene._skip_hint.visible, "hint hidden")
	assert_eq(scene._result.text, "%d pts" % scene._cascade.final_score, "lands on the real score")


func test_locking_previews_the_combo_base() -> void:
	var scene := _scene()
	scene._round.target = 1000000
	_open_window(scene)
	assert_true(scene._status.text.ends_with("TAP TO LOCK"), "no preview before any lock")
	scene._controller.faces[0] = 4
	scene._controller.faces[1] = 4
	scene._controller.faces[2] = 2
	scene._controller.lock_die(2)
	assert_true(scene._status.text.ends_with("no combo yet"), scene._status.text)
	scene._controller.lock_die(0)
	scene._controller.lock_die(1)
	var cfg: ScoringConfig = scene._scoring_config
	assert_true(scene._status.text.ends_with("PAIR · %d × %d" % [cfg.pair_chips, cfg.pair_mult]), scene._status.text)
	assert_eq(scene._hud.chips_label.text, str(cfg.pair_chips), "CHIPS shows the hand's base")
	assert_eq(scene._hud.mult_label.text, str(cfg.pair_mult), "MULT shows the hand's base")


func test_preview_ignores_charms() -> void:
	var scene := _scene()
	RunCoordinator.inventory.add_charm(load("res://resources/charms/hair_trigger.tres"))  # +5 chips per W1 lock
	scene._round.target = 1000000
	_open_window(scene)
	scene._controller.faces[0] = 6
	scene._controller.faces[1] = 6
	scene._controller.lock_die(0)
	scene._controller.lock_die(1)
	assert_eq(scene._hud.chips_label.text, str(scene._scoring_config.pair_chips), "charm bonus stays for the cascade")


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
