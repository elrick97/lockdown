extends GutTest
## Unit tests for ScoreCascade (score-cascade spec): verifies skip() resolves
## instantly and finished signal fires — no animation timing needed.


func _make_cascade() -> Array:
	var host := Node.new()
	add_child_autofree(host)
	var result_label := Label.new()
	var total_label := Label.new()
	host.add_child(result_label)
	host.add_child(total_label)
	var tumbler := DiceTumbler.new()
	add_child_autofree(tumbler)
	var config := ScoringConfig.new()
	var cascade := ScoreCascade.new(host, tumbler, result_label, total_label, config)
	return [cascade, result_label, total_label]


func _make_breakdown(score: int, combo_name: String = "") -> ScoreBreakdown:
	var bd := ScoreBreakdown.new()
	bd.final_score = score
	if combo_name != "":
		bd.combos.append({
			"name": combo_name,
			"type": 0,
			"dice_indices": [],
			"faces": [],
			"chips": 0,
			"mult": 1,
		})
	return bd


func test_skip_sets_score_label() -> void:
	var parts := _make_cascade()
	var cascade: ScoreCascade = parts[0]
	var result_label: Label = parts[1]

	cascade.play(_make_breakdown(140, "Pair"), 0, 140, 350)
	cascade.skip()

	assert_eq(result_label.text, "140 pts", "result label shows final score after skip")


func test_skip_sets_total_label() -> void:
	var parts := _make_cascade()
	var cascade: ScoreCascade = parts[0]
	var total_label: Label = parts[2]

	cascade.play(_make_breakdown(140, "Pair"), 50, 190, 350)
	cascade.skip()

	assert_eq(total_label.text, "Total: 190 / 350", "total label shows new total / target after skip")


func test_skip_emits_finished() -> void:
	var parts := _make_cascade()
	var cascade: ScoreCascade = parts[0]
	watch_signals(cascade)

	cascade.play(_make_breakdown(100), 0, 100, 350)
	cascade.skip()

	assert_signal_emitted(cascade, "finished", "finished signal emitted on skip")


func test_skip_without_play_is_safe() -> void:
	var parts := _make_cascade()
	var cascade: ScoreCascade = parts[0]
	watch_signals(cascade)

	cascade.skip()  # should not crash; emits finished with zero values

	assert_signal_emitted(cascade, "finished", "finished fires even without play")


func test_no_score_shows_zero_pts() -> void:
	var parts := _make_cascade()
	var cascade: ScoreCascade = parts[0]
	var result_label: Label = parts[1]

	cascade.play(_make_breakdown(0), 0, 0, 350)
	cascade.skip()

	assert_eq(result_label.text, "0 pts", "zero score displayed correctly")
