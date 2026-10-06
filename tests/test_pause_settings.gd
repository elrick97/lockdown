extends GutTest
## add-pause-settings: manual pause with a menu, resume rules, abandon run, and
## settings that scale presentation only (shake, score speed, motion, haptics).

const THROW_SCENE := preload("res://scenes/throw/throw_scene.tscn")
const START_SCENE := preload("res://scenes/start/start_scene.tscn")


func before_each() -> void:
	Settings.persist = false  # never touch the player's real settings file
	Settings.reset_defaults()


func after_each() -> void:
	get_tree().paused = false
	Settings.reset_defaults()
	Settings.persist = true
	RunCoordinator.new_run()


func _scene() -> Control:
	RunCoordinator.new_run(31)
	var scene: Control = THROW_SCENE.instantiate()
	var cfg := ThrowConfig.new()
	cfg.tumble_duration_s = 0.05
	cfg.lock_window_duration_s = 30.0
	scene._config = cfg
	add_child_autofree(scene)
	scene.ante_cleared.disconnect(RunCoordinator.on_ante_cleared)
	scene._intro.visible = false
	return scene


func test_pause_opens_the_menu_and_freezes_the_game() -> void:
	var scene := _scene()
	scene._pause_button.pressed.emit()
	assert_true(scene._pause_menu.visible, "menu shown")
	assert_eq(scene._pause_menu.title_label.text, "PAUSED")
	assert_true(get_tree().paused, "game paused")
	assert_true(scene._cover.visible)
	scene._on_focus_returned()
	assert_true(get_tree().paused, "regaining focus doesn't auto-resume while the menu is up")


func test_resume_when_idle_is_immediate() -> void:
	var scene := _scene()
	scene.open_pause()
	scene._pause_menu._on_resume()
	assert_false(get_tree().paused)
	assert_false(scene._cover.visible)


func test_resume_mid_window_counts_down_and_restarts_the_window() -> void:
	var scene := _scene()
	scene._on_throw_pressed()
	await wait_until(func() -> bool: return scene._controller.state == ThrowController.State.LOCK_WINDOW, 2.0)
	scene.open_pause()
	scene._pause_menu._on_resume()
	assert_true(get_tree().paused, "still frozen during the 3-2-1")
	assert_gt(scene._countdown_left, 0.0, "countdown running")


func test_abandon_ends_the_run_as_a_loss() -> void:
	var scene := _scene()
	scene.open_pause()
	scene._pause_menu._show(&"confirm")
	scene._pause_menu._on_abandon()
	assert_false(get_tree().paused)
	assert_true(scene._end_panel.visible)
	assert_true(scene._end_title.text.contains("GAME OVER"))


func test_combos_page_lists_all_eight_with_values() -> void:
	var menu := PauseMenu.new()
	add_child_autofree(menu)
	menu.open_main()
	menu._show(&"combos")
	await wait_process_frames(1)
	var texts: Array = menu._content.get_children().filter(func(c: Node) -> bool: return c is Label and not c.is_queued_for_deletion()).map(func(l: Label) -> String: return l.text)
	assert_true(texts.any(func(t: String) -> bool: return t.begins_with("Pair — 2 of a kind · 10 × 1")), str(texts))
	assert_true(texts.any(func(t: String) -> bool: return t.begins_with("Quint — 5+ of a kind · 100 × 8")), str(texts))


func test_settings_cycle_and_label() -> void:
	assert_eq(Settings.shake_label(), "Screen shake: 100%")
	Settings.cycle_shake()
	assert_eq(Settings.shake_label(), "Screen shake: 50%")
	Settings.cycle_speed()
	assert_eq(Settings.speed_label(), "Score speed: 2×")
	Settings.cycle_speed()
	assert_eq(Settings.speed_label(), "Score speed: Instant")
	Settings.toggle_reduced_motion()
	assert_eq(Settings.shake_scale(), 0.0, "reduced motion turns shake off")


func test_shake_off_never_moves_the_screen_or_tray() -> void:
	var scene := _scene()
	Settings.shake = 0.0
	scene._screen_shake(20.0, 0.3)
	scene._nudge_tray(5.0, 0.1)
	assert_null(scene._tray_tween, "no tray tween")
	assert_eq(scene.position, Vector2.ZERO)


func test_instant_score_speed_skips_the_cascade() -> void:
	var scene := _scene()
	Settings.cascade_speed = 0.0
	scene._round.target = 1000000
	scene._on_throw_pressed()
	await wait_until(func() -> bool: return scene._controller.state == ThrowController.State.LOCK_WINDOW, 2.0)
	for i in scene._controller.faces.size():
		scene._controller.lock_die(i)
	assert_false(scene._cascade.is_playing(), "cascade resolved instantly")
	assert_false(scene._throw_button.disabled, "THROW back immediately")


func test_start_screen_opens_settings_only() -> void:
	var start: Control = START_SCENE.instantiate()
	add_child_autofree(start)
	start._settings_button.pressed.emit()
	assert_true(start._settings_menu.visible)
	assert_eq(start._settings_menu.page, &"settings")
	assert_true(start._settings_menu.settings_only)
