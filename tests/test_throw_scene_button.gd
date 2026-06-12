extends GutTest
## Reproduces the exact user path: real scene, real throw_config.tres,
## button press via the pressed signal (not a direct method call).

const SCENE := preload("res://scenes/throw/throw_scene.tscn")


func test_button_press_starts_throw_with_shipped_config() -> void:
	var scene: Control = SCENE.instantiate()
	add_child_autofree(scene)
	await get_tree().process_frame
	assert_false(get_tree().paused, "tree must not be paused at launch")
	assert_false(scene._throw_button.disabled, "button enabled at launch")
	scene._throw_button.pressed.emit()
	assert_eq(scene._controller.state, ThrowController.State.TUMBLE, "throw started")
	assert_eq(scene._dice_nodes.size(), 6, "dice built")
	assert_true(scene._throw_button.disabled, "button disabled during throw")
	get_tree().paused = false
