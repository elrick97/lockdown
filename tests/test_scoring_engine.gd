extends GutTest
## combo-scoring spec scenarios. Heat is held at x1.0 (all windows expired)
## unless a test needs otherwise, so the formula math is isolated.

const WINDOW := 2.5

var _config: ScoringConfig
var _engine: ScoringEngine


func before_each() -> void:
	_config = ScoringConfig.new()
	_engine = ScoringEngine.new()


## Builds a resolved throw with every die locked and Heat x1.0 by default.
func _result(faces: Array, times: Array = [0.0, 0.0, 0.0]) -> ThrowResult:
	var r := ThrowResult.new()
	for f in faces:
		r.faces.append(int(f))
	for i in faces.size():
		r.locked_order.append(i)
	var typed_times: Array[float] = []
	for t in times:
		typed_times.append(float(t))
	r.window_remaining_s = typed_times
	return r


func _score(faces: Array) -> ScoreBreakdown:
	return _engine.score(_result(faces), _config, WINDOW, false)


# --- formula ---------------------------------------------------------------

func test_single_pair() -> void:
	var bd := _score([4, 4])
	assert_eq(bd.final_score, 18, "(8 + 10) x 1 x 1.0")
	assert_eq(bd.combos.size(), 1)
	assert_eq(bd.combos[0].name, "Pair")


func test_loose_dice_contribute_pips() -> void:
	var bd := _score([4, 4, 2])
	assert_eq(bd.pips, 10)
	assert_eq(bd.bonus_chips, 10)
	assert_eq(bd.combo_mult, 1)
	assert_eq(bd.final_score, 20, "(10 + 10) x 1 x 1.0")
	assert_eq(bd.loose_indices, [2] as Array[int], "the unmatched die is loose")


# --- partition edge cases --------------------------------------------------

func test_quad_beats_two_pairs() -> void:
	var bd := _score([4, 4, 4, 4])
	assert_eq(bd.combos.size(), 1)
	assert_eq(bd.combos[0].name, "Quad")
	assert_eq(bd.final_score, 304, "(16 + 60) x 4 x 1.0")


func test_full_house_beats_triple_plus_pair() -> void:
	var bd := _score([3, 3, 3, 5, 5])
	assert_eq(bd.combos.size(), 1)
	assert_eq(bd.combos[0].name, "Full House")
	assert_eq(bd.final_score, 207, "(19 + 50) x 3 x 1.0")


func test_large_straight_beats_small_plus_loose() -> void:
	var bd := _score([1, 2, 3, 4, 5, 6])
	assert_eq(bd.combos.size(), 1)
	assert_eq(bd.combos[0].name, "Large Straight")
	assert_eq(bd.final_score, 505, "(21 + 80) x 5 x 1.0")


func test_quint_beats_quad_plus_loose() -> void:
	var bd := _score([6, 6, 6, 6, 6])
	assert_eq(bd.combos.size(), 1)
	assert_eq(bd.combos[0].name, "Quint")
	assert_eq(bd.final_score, 1040, "(30 + 100) x 8 x 1.0")


func test_two_genuine_pairs_partition_as_two_pair() -> void:
	var bd := _score([2, 2, 5, 5])
	assert_eq(bd.combos.size(), 1)
	assert_eq(bd.combos[0].name, "Two Pair")
	assert_eq(bd.final_score, 78, "(14 + 25) x 2 x 1.0, beating two separate pairs (68)")


# --- determinism & lock state ----------------------------------------------

func test_tie_break_is_deterministic() -> void:
	var a := _score([2, 2, 5, 5])
	var b := _score([2, 2, 5, 5])
	assert_eq(a.final_score, b.final_score)
	assert_eq(_combo_names(a), _combo_names(b), "same partition every call")


func test_unlocked_die_does_not_score() -> void:
	# Three 4s present, but only two were locked → scores as a Pair, not a Triple.
	var r := _result([4, 4, 4])
	r.locked_order = [0, 1]  # die 2 left unlocked
	var bd := _engine.score(r, _config, WINDOW, false)
	assert_eq(bd.pips, 8, "only the two locked 4s count")
	assert_eq(bd.combos.size(), 1)
	assert_eq(bd.combos[0].name, "Pair")


func test_heat_applies_to_final() -> void:
	# Full-speed throw: all windows credited → x1.5 Heat.
	var r := _result([4, 4], [WINDOW, WINDOW, WINDOW])
	var bd := _engine.score(r, _config, WINDOW, false)
	assert_almost_eq(bd.heat, 1.5, 0.0001)
	assert_eq(bd.final_score, 27, "(8 + 10) x 1 x 1.5 = 27")


func _combo_names(bd: ScoreBreakdown) -> Array:
	var names: Array = []
	for c in bd.combos:
		names.append(c.name)
	return names
