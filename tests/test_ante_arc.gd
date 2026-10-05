extends GutTest
## ante-arc spec: AnteArc headless scenarios.
## Uses watch_signals to avoid GDScript lambda capture-by-value limitations.

func _cfg(targets: Array) -> AnteConfig:
	var c := AnteConfig.new()
	var typed: Array[int] = []
	for t in targets:
		typed.append(int(t))
	c.targets = typed
	return c


func test_full_run_three_antes() -> void:
	var arc := AnteArc.new(_cfg([10, 20, 30]))
	watch_signals(arc)
	arc.on_round_won()  # clears ante 1 → advance to 2
	assert_eq(arc.current_ante, 2)
	assert_signal_emitted(arc, "ante_advanced")
	arc.on_round_won()  # clears ante 2 → advance to 3
	assert_eq(arc.current_ante, 3)
	arc.on_round_won()  # clears ante 3 → run_won
	assert_signal_emitted(arc, "run_won")
	assert_signal_not_emitted(arc, "run_lost")
	assert_signal_emit_count(arc, "ante_advanced", 2, "ante_advanced fired for ante 2 and 3")


func test_run_lost_on_first_ante() -> void:
	var arc := AnteArc.new(_cfg([10, 20, 30]))
	watch_signals(arc)
	arc.on_round_lost()
	assert_signal_emitted(arc, "run_lost")
	assert_signal_not_emitted(arc, "run_won")
	assert_eq(arc.current_ante, 1, "current_ante unchanged on loss")


func test_ante_advanced_carries_correct_data() -> void:
	var arc := AnteArc.new(_cfg([150, 350, 700]))
	watch_signals(arc)
	arc.on_round_won()
	assert_signal_emitted_with_parameters(arc, "ante_advanced", [2, 350])


func test_no_double_fire_after_run_won() -> void:
	var arc := AnteArc.new(_cfg([10]))
	watch_signals(arc)
	arc.on_round_won()
	arc.on_round_won()  # should be ignored
	assert_signal_emit_count(arc, "run_won", 1, "run_won fires exactly once")


func test_custom_two_ante_headless_run() -> void:
	var arc := AnteArc.new(_cfg([50, 100]))
	watch_signals(arc)
	arc.on_round_won()  # ante 1 cleared
	assert_eq(arc.current_ante, 2)
	arc.on_round_won()  # ante 2 cleared → run_won
	assert_signal_emitted(arc, "run_won")


func test_boss_ante_window_scale() -> void:
	var cfg := AnteConfig.new()
	cfg.boss_antes = [3]
	cfg.boss_window_scale = 0.5
	assert_true(cfg.boss_antes.has(3), "ante 3 is a boss ante")
	assert_false(cfg.boss_antes.has(1), "ante 1 is not a boss ante")
	assert_false(cfg.boss_antes.has(2), "ante 2 is not a boss ante")
	var base_s := 2.5
	var effective_s := base_s * cfg.boss_window_scale
	assert_eq(effective_s, 1.25, "boss window is halved from 2.5 to 1.25 s")


func test_boss_controller_uses_halved_duration() -> void:
	var ante_cfg := AnteConfig.new()
	ante_cfg.boss_antes = [3]
	ante_cfg.boss_window_scale = 0.5

	var throw_cfg := ThrowConfig.new()
	throw_cfg.lock_window_duration_s = 2.5

	var boss_cfg := throw_cfg.duplicate() as ThrowConfig
	boss_cfg.lock_window_duration_s = throw_cfg.lock_window_duration_s * ante_cfg.boss_window_scale
	assert_eq(boss_cfg.lock_window_duration_s, 1.25)

	var bag := DiceBag.new(throw_cfg.starting_bag_size)
	var ctrl := ThrowController.new(boss_cfg, bag, RngCore.new(42))
	ctrl.start_throw()

	var dt := 1.0 / 60.0
	for _i in 10000:
		if ctrl.state == ThrowController.State.LOCK_WINDOW and ctrl.window_index == 1:
			break
		ctrl.tick(dt)
	assert_eq(ctrl.state, ThrowController.State.LOCK_WINDOW,
		"should reach lock window 1")

	var elapsed := 0.0
	while ctrl.state == ThrowController.State.LOCK_WINDOW and ctrl.window_index == 1:
		ctrl.tick(dt)
		elapsed += dt
	assert_gt(elapsed, 1.0, "boss window lasts at least 1.0 s")
	assert_lt(elapsed, 1.5, "boss window expires in under 1.5 s (halved from 2.5)")
