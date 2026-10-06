extends GutTest
## fix-tap-lock-resolution: taps resolve to the nearest die of any state, so a tap
## aimed at a locked (or shattered) die never forgives over to a neighbour.

const SCENE := preload("res://scenes/throw/throw_scene.tscn")


func after_each() -> void:
	RunCoordinator.new_run()  # the freed mid-throw scenes leave dice drawn out of the bag


func _window_scene() -> Control:
	RunCoordinator.start_run(1234)
	var scene: Control = SCENE.instantiate()
	var cfg := ThrowConfig.new()
	cfg.tumble_duration_s = 0.05
	cfg.lock_window_duration_s = 30.0  # the window stays open for the whole test
	scene._config = cfg
	add_child_autofree(scene)
	scene.ante_cleared.disconnect(RunCoordinator.on_ante_cleared)
	scene._on_throw_pressed()
	await wait_until(func() -> bool:
		return scene._controller.state == ThrowController.State.LOCK_WINDOW, 2.0)
	return scene


func _locked_count(scene: Control) -> int:
	return scene._controller.locked.count(true)


func test_tap_on_a_locked_die_never_locks_its_neighbour() -> void:
	var scene: Control = await _window_scene()
	var r0: Rect2 = scene._tumbler.die_rect(0)
	scene._try_lock_at(r0.get_center())
	assert_true(scene._controller.locked[0])
	# Re-tap the locked die at its centre and at the edge facing die 1.
	scene._try_lock_at(r0.get_center())
	scene._try_lock_at(Vector2(r0.end.x - 2.0, r0.get_center().y))
	assert_eq(_locked_count(scene), 1, "only die 0 is locked")


func test_tap_in_the_gap_next_to_a_locked_die_is_denied() -> void:
	var scene: Control = await _window_scene()
	var r0: Rect2 = scene._tumbler.die_rect(0)
	var r1: Rect2 = scene._tumbler.die_rect(1)
	scene._controller.lock_die(0)
	# A point in the gap, nearer die 0 than die 1.
	var x := r0.end.x + (r1.position.x - r0.end.x) * 0.3
	scene._try_lock_at(Vector2(x, r0.get_center().y))
	assert_false(scene._controller.locked[1], "the nearer die is locked, so nothing new locks")


func test_near_miss_still_snaps_to_an_unlocked_die() -> void:
	var scene: Control = await _window_scene()
	var r1: Rect2 = scene._tumbler.die_rect(1)
	scene._try_lock_at(Vector2(r1.position.x - 8.0, r1.get_center().y))
	assert_true(scene._controller.locked[1], "forgiveness still works in the gaps")


func test_tap_on_a_locked_die_wiggles_it_back_home() -> void:
	var scene: Control = await _window_scene()
	scene._controller.lock_die(2)
	var node: Node3D = scene._tumbler._dice_nodes[2]
	var home := node.position
	for i in 3:  # repeated taps mid-wiggle must not drift the die
		scene._try_lock_at(scene._tumbler.die_rect(2).get_center())
		await wait_process_frames(2)
	await wait_seconds(0.4)
	assert_almost_eq(node.position.x, home.x, 0.001, "die settles exactly where it was")
