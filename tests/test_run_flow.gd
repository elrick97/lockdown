extends GutTest
## run-flow spec: new runs reset everything; the run summary keeps the best throw;
## the throw screen shows the end-of-run panel on win and on loss.

const THROW_SCENE := preload("res://scenes/throw/throw_scene.tscn")


func test_new_run_resets_run_state_and_reseeds() -> void:
	RunCoordinator.start_run(111)
	RunCoordinator.arc.current_ante = 3
	RunCoordinator.ledger.earn(9)
	RunCoordinator.bag.add(&"glass", 2)
	RunCoordinator.record_throw(150)
	RunCoordinator.new_run(222)
	assert_eq(RunCoordinator.arc.current_ante, 1, "back to ante 1")
	assert_eq(RunCoordinator.ledger.gold, 0, "gold reset")
	assert_eq(RunCoordinator.inventory.iter_charms().size(), 0, "no charms")
	assert_true(RunCoordinator.trinket_inventory.iter_trinkets().is_empty(), "no trinkets")
	var cfg: ThrowConfig = load("res://resources/throw_config.tres")
	assert_eq(RunCoordinator.bag.available(), cfg.starting_bag_size, "starting bag")
	assert_eq(RngService.run_seed, 222, "new seed")
	assert_eq(RunCoordinator.best_throw, 0, "summary reset")


func test_best_throw_keeps_the_maximum() -> void:
	RunCoordinator.new_run(5)
	for s in [40, 120, 90]:
		RunCoordinator.record_throw(s)
	assert_eq(RunCoordinator.best_throw, 120)


func _scene() -> Control:
	RunCoordinator.new_run(77)
	var scene: Control = THROW_SCENE.instantiate()
	add_child_autofree(scene)
	scene.ante_cleared.disconnect(RunCoordinator.on_ante_cleared)
	return scene


func test_end_panel_hidden_during_play() -> void:
	var scene := _scene()
	assert_false(scene._end_panel.visible, "no panel while the run is on")


func test_game_over_shows_panel_with_summary() -> void:
	var scene := _scene()
	RunCoordinator.record_throw(64)
	RunCoordinator.arc.on_round_lost()
	assert_true(scene._end_panel.visible, "panel shown on loss")
	assert_true(scene._end_title.text.to_upper().contains("GAME OVER"))
	assert_true(scene._end_summary.text.contains("64"), "best throw listed")
	assert_true(scene._end_summary.text.contains("1 / 3"), "ante reached listed")
	assert_true(scene._throw_button.disabled, "THROW stays disabled")
	assert_false(scene._new_run_button.disabled)
	assert_false(scene._menu_button.disabled)


func test_run_won_shows_panel() -> void:
	var scene := _scene()
	RunCoordinator.arc.current_ante = 3
	RunCoordinator.arc.on_round_won()
	assert_true(scene._end_panel.visible, "panel shown on win")
	assert_true(scene._end_title.text.to_upper().contains("RUN WON"))


func test_end_panel_buttons_meet_tap_size_in_thumb_zone() -> void:
	var scene := _scene()
	RunCoordinator.arc.on_round_lost()
	await wait_frames(2)
	for b: Button in [scene._new_run_button, scene._menu_button]:
		var r := b.get_global_rect()
		assert_gte(r.size.y, 126.0, "%s tall enough" % b.text)
		assert_gte(r.position.y, 2400.0 * 0.6, "%s in the bottom 40%%" % b.text)
