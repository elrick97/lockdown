extends GutTest
## Round-loop smoke test: drives the throw scene through a full 3-ante run
## using sped-up tunables and tiny ante targets so every throw wins.

const SCENE := preload("res://scenes/throw/throw_scene.tscn")


func before_each() -> void:
	RunCoordinator.start_run()


func _fast_config() -> ThrowConfig:
	var cfg := ThrowConfig.new()
	cfg.tumble_duration_s = 0.05
	cfg.lock_window_duration_s = 0.1
	return cfg


func _tiny_ante_config() -> AnteConfig:
	var cfg := AnteConfig.new()
	var targets: Array[int] = [1, 1, 1]
	cfg.targets = targets
	cfg.throws_per_round = 1  # one throw per round keeps the test short
	return cfg


## In tests the ante_cleared signal would normally trigger a shop scene
## transition via RunCoordinator. Disconnect that and wire a direct round-reset
## so multi-ante smoke tests can keep running in the same scene.
func _patch_ante_transition(scene: Control, ante_cfg: AnteConfig) -> void:
	scene.ante_cleared.disconnect(RunCoordinator.on_ante_cleared)
	scene.ante_cleared.connect(func(_throws_left: int) -> void:
		if scene._arc._run_done:
			return
		scene._round = RoundState.new(
			scene._arc.target_for(scene._arc.current_ante),
			ante_cfg.throws_per_round)
		scene._round.round_won.connect(scene._on_round_won)
		scene._round.round_lost.connect(scene._on_round_lost)
		scene._throw_button.disabled = false
		scene._update_round_labels()
	)


func _do_throw(scene: Control) -> void:
	scene._on_throw_pressed()
	await wait_until(func() -> bool:
		return scene._controller.state == ThrowController.State.RESOLVED, 3.0)


func test_full_run_reaches_terminal_state() -> void:
	var tiny_cfg := _tiny_ante_config()
	RunCoordinator.arc = AnteArc.new(tiny_cfg)
	var scene: Control = SCENE.instantiate()
	scene._config = _fast_config()
	scene._ante_config = tiny_cfg
	add_child_autofree(scene)
	_patch_ante_transition(scene, tiny_cfg)

	# Throw 1: ante 1. Score > 1 always, so ante 1 clears → ante_advanced fires.
	await _do_throw(scene)
	assert_eq(scene._arc.current_ante, 2, "ante advances to 2 after throw 1")

	# Throw 2: ante 2. Score > 1 → ante 2 clears.
	await _do_throw(scene)
	assert_eq(scene._arc.current_ante, 3, "ante advances to 3 after throw 2")

	# Throw 3: ante 3. Score > 1 → run_won fires.
	await _do_throw(scene)
	assert_true(scene._arc._run_done, "run is done after clearing all antes")
	assert_true(scene._status.text.contains("WIN"), "status shows win message")
	assert_true(scene._throw_button.disabled, "throw button disabled at run end")


func test_ante_label_reflects_current_ante() -> void:
	var tiny_cfg := _tiny_ante_config()
	RunCoordinator.arc = AnteArc.new(tiny_cfg)
	var scene: Control = SCENE.instantiate()
	scene._config = _fast_config()
	scene._ante_config = tiny_cfg
	add_child_autofree(scene)
	_patch_ante_transition(scene, tiny_cfg)

	await _do_throw(scene)
	assert_true(scene._ante_label.text.contains("2"), "ante label shows ante 2 after first clear")


func test_round_lost_shows_game_over() -> void:
	var cfg := AnteConfig.new()
	var targets: Array[int] = [999999]
	cfg.targets = targets
	cfg.throws_per_round = 1
	RunCoordinator.arc = AnteArc.new(cfg)
	var scene: Control = SCENE.instantiate()
	scene._config = _fast_config()
	scene._ante_config = cfg
	add_child_autofree(scene)

	await _do_throw(scene)
	assert_true(scene._arc._run_done, "run done after losing")
	assert_true(scene._status.text.contains("GAME OVER"), "status shows game over")
	assert_true(scene._throw_button.disabled, "throw button disabled after loss")
