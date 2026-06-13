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
