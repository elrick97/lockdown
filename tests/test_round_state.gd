extends GutTest
## round-loop spec: RoundState headless scenarios.
## Uses watch_signals to avoid GDScript lambda capture-by-value limitations.

func test_win_on_first_throw() -> void:
	var r := RoundState.new(100)
	watch_signals(r)
	r.add_score(100)
	assert_signal_emitted(r, "round_won", "round_won fires when score meets target on throw 1")
	assert_signal_not_emitted(r, "round_lost")
	assert_eq(r.current_throw, 1)
	assert_eq(r.total, 100)
	assert_true(r.is_done)


func test_win_after_accumulation() -> void:
	var r := RoundState.new(150)
	watch_signals(r)
	r.add_score(80)
	assert_signal_not_emitted(r, "round_won", "not won after throw 1 with 80")
	r.add_score(70)
	assert_signal_emitted(r, "round_won", "round_won fires when accumulated total >= target")
	assert_signal_not_emitted(r, "round_lost")
	assert_eq(r.current_throw, 2)


func test_lose_on_final_throw() -> void:
	var r := RoundState.new(500)
	watch_signals(r)
	r.add_score(50)
	r.add_score(50)
	r.add_score(50)
	assert_signal_not_emitted(r, "round_won")
	assert_signal_emitted(r, "round_lost", "round_lost fires when all throws used without reaching target")
	assert_eq(r.current_throw, 3)
	assert_true(r.is_done)


func test_signal_fires_exactly_once() -> void:
	var r := RoundState.new(10)
	watch_signals(r)
	r.add_score(10)
	r.add_score(10)  # already done — should be ignored
	assert_signal_emit_count(r, "round_won", 1, "round_won fires exactly once")


func test_add_score_ignored_after_done() -> void:
	var r := RoundState.new(10)
	watch_signals(r)
	r.add_score(10)
	assert_true(r.is_done)
	r.add_score(999)
	assert_eq(r.total, 10, "total unchanged after is_done")
	assert_eq(r.current_throw, 1, "throw counter unchanged after is_done")


func test_reset_reinitialises() -> void:
	var r := RoundState.new(100)
	watch_signals(r)
	r.add_score(100)
	assert_true(r.is_done)
	r.reset(200)
	assert_eq(r.target, 200)
	assert_eq(r.current_throw, 0)
	assert_eq(r.total, 0)
	assert_false(r.is_done)
	r.add_score(200)
	assert_signal_emitted(r, "round_won", "round works normally after reset")
