extends GutTest
## End-to-end smoke test: the real throw scene, in-tree, with sped-up tunables.
## Verifies the scene drives the controller through a full throw and that the
## tap-forgiveness path locks dice.

const SCENE := preload("res://scenes/throw/throw_scene.tscn")


func _fast_config() -> ThrowConfig:
	var cfg := ThrowConfig.new()
	cfg.tumble_duration_s = 0.05
	cfg.lock_window_duration_s = 0.1
	return cfg


func test_full_throw_resolves_on_screen() -> void:
	var scene: Control = SCENE.instantiate()
	scene._config = _fast_config()
	add_child_autofree(scene)
	scene._on_throw_pressed()
	assert_eq(scene._dice_nodes.size(), 6, "gray-box dice built on throw")
	# Let tumble finish, then tap-lock the first die through the forgiveness path.
	await wait_until(func() -> bool:
		return scene._controller.state == ThrowController.State.LOCK_WINDOW, 2.0)
	var die_center: Vector2 = scene._dice_nodes[0].get_global_rect().get_center()
	scene._try_lock_at(die_center + Vector2(scene._config.tap_forgiveness_radius_px - 1.0, 0.0))
	assert_true(scene._controller.locked[0], "tap within forgiveness radius locks the die")
	# Let the remaining windows expire to force-lock and resolve.
	await wait_until(func() -> bool:
		return scene._controller.state == ThrowController.State.RESOLVED, 5.0)
	assert_eq(scene._controller.state, ThrowController.State.RESOLVED, "throw resolved end-to-end")
	assert_ne(scene._result.text, "", "resolve readout displayed")
	assert_false(scene._throw_button.disabled, "throw button re-enabled after resolve")
