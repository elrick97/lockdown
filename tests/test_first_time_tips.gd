extends GutTest
## add-first-time-tips: each tip shows once, is remembered, respects the toggle, and
## never blocks a die tap.

const THROW_SCENE := preload("res://scenes/throw/throw_scene.tscn")


func before_each() -> void:
	Settings.persist = false
	Settings.reset_defaults()


func after_each() -> void:
	Settings.reset_defaults()
	RunCoordinator.new_run()


func test_take_tip_once_and_toggle() -> void:
	assert_true(Settings.take_tip("x"), "first time")
	assert_false(Settings.take_tip("x"), "never again")
	Settings.reset_tips()
	assert_true(Settings.take_tip("x"), "Show tips again resets")
	Settings.toggle_tips()
	assert_false(Settings.take_tip("y"), "off means no tips")


func test_tests_never_persist_settings() -> void:
	Settings._ready()
	assert_false(Settings.persist, "running under GUT never writes the player's file")


func _window_scene() -> Control:
	RunCoordinator.new_run(77)
	var scene: Control = THROW_SCENE.instantiate()
	var cfg := ThrowConfig.new()
	cfg.tumble_duration_s = 0.05
	cfg.lock_window_duration_s = 30.0
	scene._config = cfg
	add_child_autofree(scene)
	scene.ante_cleared.disconnect(RunCoordinator.on_ante_cleared)
	scene._intro.visible = false
	scene._on_throw_pressed()
	await wait_until(func() -> bool: return scene._controller.state == ThrowController.State.LOCK_WINDOW, 2.0)
	return scene


func test_first_window_tip_shows_once_and_never_blocks_a_lock() -> void:
	var scene: Control = await _window_scene()
	assert_true(scene._coach.visible)
	assert_true(scene._coach.label.text.begins_with("Tap a die"))
	assert_eq(scene._coach.mouse_filter, Control.MOUSE_FILTER_IGNORE)
	scene._try_lock_at(scene._tumbler.die_rect(1).get_center())
	assert_true(scene._controller.locked[1], "locks through the tip")
	scene._coach.visible = false
	scene._on_window_started(1)
	assert_false(scene._coach.visible, "first-window tip never repeats")


func test_tips_off_shows_nothing() -> void:
	Settings.tips_enabled = false
	var scene: Control = await _window_scene()
	assert_false(scene._coach.visible)
