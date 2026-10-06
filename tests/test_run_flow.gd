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


func test_end_panel_dims_everything_and_counts_the_total_up() -> void:
	var scene := _scene()
	scene._round.total = 420
	RunCoordinator.arc.on_round_lost()
	for c in [scene._charm_row, scene._hud, scene._throw_button, scene._tray]:
		assert_lt((c as Node).get_index(), scene._end_panel.get_index(), "%s is dimmed by the panel" % c.name)
	assert_lt(scene._end_panel.get_index(), scene._cover.get_index(), "focus cover stays on top")
	assert_false(scene._throw_button.visible, "THROW hidden behind the panel")
	assert_eq(scene._end_score.text, "0", "final total starts at 0")
	await wait_seconds(2.5)
	assert_eq(scene._end_score.text, "420", "and counts up to the final total")
	assert_true(scene._end_score_caption.text.contains(str(scene._round.target)), "target shown")


func test_end_panel_buttons_meet_tap_size_in_thumb_zone() -> void:
	var scene := _scene()
	RunCoordinator.arc.on_round_lost()
	await wait_frames(2)
	for b: Button in [scene._new_run_button, scene._menu_button]:
		var r := b.get_global_rect()
		assert_gte(r.size.y, 126.0, "%s tall enough" % b.text)
		assert_gte(r.position.y, 2400.0 * 0.6, "%s in the bottom 40%%" % b.text)


# --- add-run-summary-stats ---

func test_end_panel_says_how_close_and_the_run_stats() -> void:
	var scene := _scene()
	RunCoordinator.record_throw(64)
	RunCoordinator.record_combos([{"type": ScoringConfig.ComboType.PAIR}, {"type": ScoringConfig.ComboType.FULL_HOUSE}])
	scene._round.total = 57
	RunCoordinator.arc.on_round_lost()
	assert_eq(scene._end_result.text, "MISSED BY %d" % (scene._round.target - 57))
	assert_true(scene._end_summary.text.contains("Best combo: Full House"), scene._end_summary.text)
	assert_true(scene._end_summary.text.contains("Rounds cleared 0"))
	assert_true(scene._end_seed.text.begins_with("Seed %d" % RngService.run_seed))
	assert_eq(scene._status.text, "", "nothing stale behind the panel")


func test_win_shows_the_margin() -> void:
	var scene := _scene()
	scene._round.total = scene._round.target + 205
	RunCoordinator.arc.current_ante = 3
	RunCoordinator.arc.on_round_won()
	assert_eq(scene._end_result.text, "BEAT BY 205")


func test_empty_build_reads_no_charms() -> void:
	var scene := _scene()
	RunCoordinator.arc.on_round_lost()
	assert_true(scene._end_empty_build.visible, "says there were no charms")
	assert_false(scene._end_build.visible, "instead of five empty sockets")


func test_run_stats_count_clears_and_gold() -> void:
	RunCoordinator.new_run(6)
	RunCoordinator.on_ante_cleared(1)
	assert_eq(RunCoordinator.rounds_cleared, 1)
	assert_eq(RunCoordinator.gold_earned, RunCoordinator.ledger.gold, "all gold so far was earned")
	RunCoordinator.new_run(7)
	assert_eq(RunCoordinator.rounds_cleared, 0, "reset with the run")
	assert_eq(RunCoordinator.best_combo_type, -1)


func test_end_panel_closes_the_intro_card() -> void:
	var scene := _scene()
	assert_true(scene._intro.visible)
	RunCoordinator.arc.on_round_lost()
	assert_false(scene._intro.visible, "nothing from the intro peeks behind the end panel")
