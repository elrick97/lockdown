extends GutTest
## End-to-end smoke test: the real throw scene, in-tree, with sped-up tunables.
## Verifies the scene drives the controller through a full throw and that the
## tap-forgiveness path locks dice.

const SCENE := preload("res://scenes/throw/throw_scene.tscn")
## Fixed seed: with a random one, a strong hand sometimes won the round and THROW
## (correctly) stayed disabled, failing the re-enable assert about 1 run in 4.
const SMOKE_SEED := 1234


func before_each() -> void:
	RunCoordinator.start_run(SMOKE_SEED)


func _fast_config() -> ThrowConfig:
	var cfg := ThrowConfig.new()
	cfg.tumble_duration_s = 0.05
	cfg.lock_window_duration_s = 0.1
	return cfg


func test_full_throw_resolves_on_screen() -> void:
	var scene: Control = SCENE.instantiate()
	scene._config = _fast_config()
	add_child_autofree(scene)
	# Prevent accidental ante-clear from triggering a shop scene transition.
	scene.ante_cleared.disconnect(RunCoordinator.on_ante_cleared)
	scene._on_throw_pressed()
	assert_eq(scene._tumbler.count, 6, "tumbler built dice on throw")
	# Let tumble finish, then tap-lock the first die through the forgiveness path.
	await wait_until(func() -> bool:
		return scene._controller.state == ThrowController.State.LOCK_WINDOW, 2.0)
	var die_center: Vector2 = scene._tumbler.die_rect(0).get_center()
	scene._try_lock_at(die_center + Vector2(scene._config.tap_forgiveness_radius_px - 1.0, 0.0))
	assert_true(scene._controller.locked[0], "tap within forgiveness radius locks the die")
	# Let the remaining windows expire to force-lock and resolve.
	await wait_until(func() -> bool:
		return scene._controller.state == ThrowController.State.RESOLVED, 5.0)
	assert_eq(scene._controller.state, ThrowController.State.RESOLVED, "throw resolved end-to-end")
	# Skip cascade so game state updates synchronously in the test.
	if scene._cascade != null:
		scene._cascade.skip()
	assert_ne(scene._result.text, "", "resolve readout displayed")
	assert_true(scene._result.text.contains("pts"), "readout shows score after cascade")
	assert_false(scene._throw_button.disabled, "throw button re-enabled after cascade")
	# Score the same resolved throw directly and confirm a real, non-negative total.
	var bd := ScoringEngine.new().score(
		scene._controller.last_result, scene._scoring_config,
		scene._config.lock_window_duration_s, false)
	assert_gt(bd.final_score, 0, "a resolved throw produces a positive score")
	# Status after resolve is either "X scored · Y to go · N throws left" (mid-round) or
	# a round-end/ante message depending on whether the target was hit.
	assert_ne(scene._status.text, "Tumbling…", "status updated from tumble message after resolve")


func test_boss_ante_halves_window_and_shows_boss_label() -> void:
	RunCoordinator.arc.current_ante = 3
	var scene: Control = SCENE.instantiate()
	add_child_autofree(scene)
	assert_eq(scene._effective_window_s, scene._config.lock_window_duration_s * 0.5,
			"boss ante (3) halves the effective window duration")
	assert_true(scene._ante_label.text.contains("BOSS ROUND"),
			"ante label reads BOSS ROUND on a boss ante")


func test_non_boss_ante_uses_full_window() -> void:
	RunCoordinator.arc.current_ante = 1
	var scene: Control = SCENE.instantiate()
	add_child_autofree(scene)
	assert_eq(scene._effective_window_s, scene._config.lock_window_duration_s,
			"non-boss ante (1) uses the full window duration")


func test_risk_ante_shows_skip_button() -> void:
	RunCoordinator.arc.current_ante = 2
	var scene: Control = SCENE.instantiate()
	add_child_autofree(scene)
	assert_true(scene._skip_button.visible, "skip button visible on risk ante 2")


func test_non_risk_ante_hides_skip_button() -> void:
	RunCoordinator.arc.current_ante = 1
	var scene: Control = SCENE.instantiate()
	add_child_autofree(scene)
	assert_false(scene._skip_button.visible, "skip button hidden on ante 1")


func test_trinket_button_appears_and_consumes_on_press() -> void:
	var scene: Control = SCENE.instantiate()
	scene._config = _fast_config()
	add_child_autofree(scene)
	scene.ante_cleared.disconnect(RunCoordinator.on_ante_cleared)
	var t := Trinket.new()
	t.display_name = "Test Trinket"
	RunCoordinator.trinket_inventory.add_trinket(t)
	scene._on_throw_pressed()
	assert_eq(scene._trinket_row.get_child_count(), 1, "one trinket button built")
	var btn := scene._trinket_row.get_child(0) as Button
	assert_eq(btn.text, "Test Trinket", "button labelled with trinket display_name")
	btn.pressed.emit()
	assert_eq(RunCoordinator.trinket_inventory.iter_trinkets().size(), 0,
			"trinket consumed after activation")
	await get_tree().process_frame  # queue_free() on the old button defers removal
	assert_eq(scene._trinket_row.get_child_count(), 0,
			"trinket row rebuilt empty after the only trinket is consumed")


func test_carve_activated_spark_extends_current_window() -> void:
	var scene: Control = SCENE.instantiate()
	scene._config = _fast_config()
	add_child_autofree(scene)
	scene.ante_cleared.disconnect(RunCoordinator.on_ante_cleared)
	scene._on_throw_pressed()
	await wait_until(func() -> bool:
		return scene._controller.state == ThrowController.State.LOCK_WINDOW, 2.0)
	scene._controller.tick(scene._config.lock_window_duration_s * 0.5)
	var before: float = scene._controller.time_remaining()
	scene._on_carve_activated(0, &"spark")
	assert_gt(scene._controller.time_remaining(), before,
			"_on_carve_activated(spark) extends the current lock window")


func test_carve_activated_ignores_non_spark_types() -> void:
	var scene: Control = SCENE.instantiate()
	scene._config = _fast_config()
	add_child_autofree(scene)
	scene.ante_cleared.disconnect(RunCoordinator.on_ante_cleared)
	scene._on_throw_pressed()
	await wait_until(func() -> bool:
		return scene._controller.state == ThrowController.State.LOCK_WINDOW, 2.0)
	scene._controller.tick(scene._config.lock_window_duration_s * 0.5)
	var before: float = scene._controller.time_remaining()
	scene._on_carve_activated(0, &"gem")
	assert_eq(scene._controller.time_remaining(), before,
			"gem/wild carve types do not affect the window timer")


## Taps resolve from the input event's position, not the OS cursor: on a phone
## (touch emulated as mouse) and in tests there is no cursor to read.
func test_tap_uses_event_position_not_cursor() -> void:
	var scene: Control = SCENE.instantiate()
	scene._config = _fast_config()
	scene._config.lock_window_duration_s = 5.0
	add_child_autofree(scene)
	scene.ante_cleared.disconnect(RunCoordinator.on_ante_cleared)
	scene._on_throw_pressed()
	await wait_until(func() -> bool:
		return scene._controller.state == ThrowController.State.LOCK_WINDOW, 2.0)
	var target: Vector2 = scene._tumbler.die_rect(2).get_center()
	var ev := InputEventMouseButton.new()
	ev.button_index = MOUSE_BUTTON_LEFT
	ev.pressed = true
	ev.position = scene.get_global_transform().affine_inverse() * target  # _gui_input gets local coords
	ev.global_position = target
	scene._gui_input(ev)
	assert_true(scene._controller.locked[2], "the die under the event position locks")
	assert_eq(scene._controller.locked.count(true), 1, "and only that die")


## Focus-loss protection (throw-loop spec) must also fire for a window/tab blur: on
## the web that is the only focus signal (no application focus notification).
func test_window_focus_loss_pauses_and_covers() -> void:
	for pair in [[NOTIFICATION_APPLICATION_FOCUS_OUT, NOTIFICATION_APPLICATION_FOCUS_IN],
			[NOTIFICATION_WM_WINDOW_FOCUS_OUT, NOTIFICATION_WM_WINDOW_FOCUS_IN]]:
		var scene: Control = SCENE.instantiate()
		add_child_autofree(scene)
		scene._notification(pair[0])
		assert_true(get_tree().paused, "focus out (%d) pauses the game" % pair[0])
		assert_true(scene._cover.visible, "and covers the tray")
		scene._notification(pair[1])
		assert_gt(scene._countdown_left, 0.0, "focus in (%d) starts the resume countdown" % pair[1])
		get_tree().paused = false
		scene._cover.visible = false


func test_resume_countdown_survives_a_long_first_frame() -> void:
	var scene: Control = SCENE.instantiate()
	add_child_autofree(scene)
	scene._notification(NOTIFICATION_WM_WINDOW_FOCUS_OUT)
	scene._notification(NOTIFICATION_WM_WINDOW_FOCUS_IN)
	scene._process(30.0)  # a hidden tab's first frame back
	assert_gt(scene._countdown_left, 0.0, "the 3-2-1 countdown is not skipped")
	assert_true(scene._cover.visible, "still covered during the countdown")
	get_tree().paused = false
