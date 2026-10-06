extends GutTest
## ScoreCascade (score-cascade spec): the display steps sum to the breakdown exactly,
## shake grows with the combo tier, skip() resolves instantly, and the playing
## cascade ends on the same state skip() jumps to.

const WINDOW := 2.5


func _make_cascade() -> Array:
	var host := Control.new()
	add_child_autofree(host)
	var result_label := Label.new()
	var total_label := Label.new()
	host.add_child(result_label)
	host.add_child(total_label)
	var hud := ScoreHud.new()
	host.add_child(hud)
	var tumbler := DiceTumbler.new()
	add_child_autofree(tumbler)
	var fx := FeedbackConfig.new()
	var cascade := ScoreCascade.new(host, tumbler, hud, result_label, total_label, ScoringConfig.new(), fx)
	return [cascade, result_label, total_label, hud]


func _make_breakdown(score: int, combo_name: String = "") -> ScoreBreakdown:
	var bd := ScoreBreakdown.new()
	bd.final_score = score
	if combo_name != "":
		bd.combos.append({"name": combo_name, "type": 0, "dice_indices": [], "faces": [], "chips": 0, "mult": 1})
	return bd


func _result(faces: Array, windows: Array = []) -> ThrowResult:
	var r := ThrowResult.new()
	for i in faces.size():
		r.faces.append(int(faces[i]))
		r.locked_order.append(i)
		r.lock_windows.append(int(windows[i]) if i < windows.size() else 1)
	r.window_remaining_s = [1.0, 2.5, 2.5]
	return r


func _assert_steps_match(bd: ScoreBreakdown, what: String) -> void:
	var sums := ScoreCascade.sum_steps(ScoreCascade.build_steps(bd, ScoringConfig.new().base_mult))
	assert_eq(int(sums.chips), bd.pips + bd.bonus_chips + bd.charm_chips, "%s: chips steps sum" % what)
	assert_almost_eq(float(sums.mult), float(bd.combo_mult) + bd.charm_mult, 0.0001, "%s: mult steps sum" % what)
	assert_eq(floori(float(sums.chips) * float(sums.mult) * bd.heat), bd.final_score,
		"%s: shown Chips × Mult × Heat equals the score" % what)


func test_steps_sum_to_breakdown_across_hands() -> void:
	var engine := ScoringEngine.new()
	var cfg := ScoringConfig.new()
	var hands := {
		"loose": [2, 5], "pair": [4, 4, 1], "full house": [3, 3, 3, 6, 6],
		"quint": [5, 5, 5, 5, 5], "large straight": [1, 2, 3, 4, 5, 6],
	}
	for name: String in hands:
		_assert_steps_match(engine.score(_result(hands[name]), cfg, WINDOW), name)


func test_steps_sum_with_charms_and_rewrites() -> void:
	var inv := CharmInventory.new()
	inv.add_charm(CharmHairTrigger.new())
	inv.add_charm(CharmSnakeCharmer.new())  # rewrites combo mult, zeroes bonus chips
	inv.add_charm(CharmCollector.new())
	var bd := ScoringEngine.new().score(_result([1, 1, 4]), ScoringConfig.new(), WINDOW, false, inv)
	assert_eq(bd.charm_triggers.size(), 3)
	_assert_steps_match(bd, "snake eyes + charms")


func test_steps_sum_with_glass_gem_and_iron() -> void:
	var r := _result([5, 5, 2])
	r.pip_multipliers = [2, 1, 1]  # Glass
	r.pip_offsets = [0, 0, -1]  # Iron
	r.carve_types = [&"", &"gem", &""]
	var bd := ScoringEngine.new().score(r, ScoringConfig.new(), WINDOW)
	assert_eq(bd.gem_chips, 20)
	_assert_steps_match(bd, "glass + gem + iron")


func test_one_step_per_scoring_die_in_index_order() -> void:
	var bd := ScoringEngine.new().score(_result([6, 2, 6]), ScoringConfig.new(), WINDOW)
	var dice := ScoreCascade.build_steps(bd, 1).filter(func(s: Dictionary) -> bool: return s.kind == &"die")
	assert_eq(dice.map(func(s: Dictionary) -> int: return s.idx), [0, 1, 2])
	assert_eq(dice.map(func(s: Dictionary) -> int: return s.chips), [6, 2, 6])


func test_shake_and_sparks_rise_with_tier() -> void:
	var fx := FeedbackConfig.new()
	for t in range(1, 6):
		assert_gt(fx.shake_px_by_tier[t], fx.shake_px_by_tier[t - 1], "shake grows at tier %d" % t)
		assert_gt(fx.sparks_by_tier[t], fx.sparks_by_tier[t - 1], "sparks grow at tier %d" % t)
	assert_eq(FeedbackConfig.tier_of_type(ScoringConfig.ComboType.PAIR), 1)
	assert_eq(FeedbackConfig.tier_of_type(ScoringConfig.ComboType.FULL_HOUSE), 3)
	assert_eq(FeedbackConfig.tier_of_type(ScoringConfig.ComboType.QUINT), 5)


func test_bigger_scores_tick_longer_up_to_the_cap() -> void:
	var fx := FeedbackConfig.new()
	assert_lt(fx.tick_s(20, 0.8), fx.tick_s(2000, 0.8))
	assert_lte(fx.tick_s(10000000, 0.8), fx.tick_max_s)


func test_no_combo_no_stamp_no_shake() -> void:
	var parts := _make_cascade()
	var cascade: ScoreCascade = parts[0]
	watch_signals(cascade)
	var bd := ScoringEngine.new().score(_result([2, 5]), ScoringConfig.new(), WINDOW)
	cascade.play(bd, 0, bd.final_score, 150)
	await wait_seconds(1.2)
	assert_signal_not_emitted(cascade, "shake_requested", "no combo → no shake")
	cascade.skip()


func test_combo_requests_tier_shake_and_ends_matching_skip() -> void:
	var parts := _make_cascade()
	var cascade: ScoreCascade = parts[0]
	var hud: ScoreHud = parts[3]
	watch_signals(cascade)
	var bd := ScoringEngine.new().score(_result([3, 3, 3, 6, 6]), ScoringConfig.new(), WINDOW)
	cascade.play(bd, 100, 100 + bd.final_score, 150)
	await wait_for_signal(cascade.finished, 10.0)
	var fx := FeedbackConfig.new()
	assert_signal_emitted_with_parameters(cascade, "shake_requested", [fx.shake_px_by_tier[3], fx.shake_s_by_tier[3]], 0)
	assert_signal_emitted(cascade, "target_hit", "crossing the target fires the flourish")
	var sums := ScoreCascade.sum_steps(ScoreCascade.build_steps(bd, 1))
	assert_eq(hud.chips_label.text, str(sums.chips), "CHIPS lands on the breakdown")
	assert_eq(hud.mult_label.text, ScoreHud.fmt_mult(sums.mult), "MULT lands on the breakdown")
	assert_eq((parts[1] as Label).text, "%d pts" % bd.final_score)


func test_skip_sets_score_label() -> void:
	var parts := _make_cascade()
	var cascade: ScoreCascade = parts[0]
	cascade.play(_make_breakdown(140, "Pair"), 0, 140, 350)
	cascade.skip()
	assert_eq((parts[1] as Label).text, "140 pts", "result label shows final score after skip")


func test_skip_sets_total_label_and_clears_effects() -> void:
	var parts := _make_cascade()
	var cascade: ScoreCascade = parts[0]
	var hud: ScoreHud = parts[3]
	var bd := ScoringEngine.new().score(_result([4, 4, 4]), ScoringConfig.new(), WINDOW)
	cascade.play(bd, 50, 50 + bd.final_score, 350)
	await wait_seconds(0.5)
	cascade.skip()
	assert_eq((parts[2] as Label).text, ScoreHud.total_text(50 + bd.final_score, 350))
	assert_eq(hud.transient_count(), 0, "floats and sparks cleared")
	assert_false(hud.stamp_label.visible, "stamp cleared")


func test_skip_emits_finished_once() -> void:
	var parts := _make_cascade()
	var cascade: ScoreCascade = parts[0]
	watch_signals(cascade)
	cascade.play(_make_breakdown(100), 0, 100, 350)
	cascade.skip()
	cascade.skip()
	assert_signal_emit_count(cascade, "finished", 1)


func test_skip_without_play_is_safe() -> void:
	var parts := _make_cascade()
	var cascade: ScoreCascade = parts[0]
	watch_signals(cascade)
	cascade.skip()
	assert_signal_emitted(cascade, "finished", "finished fires even without play")


func test_no_score_shows_zero_pts() -> void:
	var parts := _make_cascade()
	var cascade: ScoreCascade = parts[0]
	cascade.play(_make_breakdown(0), 0, 0, 350)
	cascade.skip()
	assert_eq((parts[1] as Label).text, "0 pts", "zero score displayed correctly")
