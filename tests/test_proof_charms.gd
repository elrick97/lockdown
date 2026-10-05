extends GutTest
## Headless tests for the three proof-of-concept charms (charm-effect spec).

const WINDOW := 2.5

var _config: ScoringConfig
var _engine: ScoringEngine


func before_each() -> void:
	_config = ScoringConfig.new()
	_engine = ScoringEngine.new()


func _result(faces: Array, lock_windows: Array = []) -> ThrowResult:
	var r := ThrowResult.new()
	for f in faces:
		r.faces.append(int(f))
	for i in faces.size():
		r.locked_order.append(i)
		r.lock_windows.append(lock_windows[i] if i < lock_windows.size() else 1)
	return r


func _inv(charm: CharmEffect) -> CharmInventory:
	var inv := CharmInventory.new()
	inv.add_charm(charm)
	return inv


# --- Quick Draw ---------------------------------------------------------------

func test_quick_draw_all_window1_pair_of_4s() -> void:
	# Pair of 4s locked in window 1 → (8 + 10) × (1 + 2) × 1.0 = 54.
	var r := _result([4, 4], [1, 1])
	var bd := _engine.score(r, _config, WINDOW, false, _inv(CharmQuickDraw.new()))
	assert_almost_eq(bd.charm_mult, 2.0, 0.001)
	assert_eq(bd.final_score, 54, "(8 + 10) x (1 + 2) x 1.0 = 54")


func test_quick_draw_no_bonus_when_mixed_windows() -> void:
	# First die in window 1, second in window 2 → no Quick Draw bonus.
	var r := _result([4, 4], [1, 2])
	var bd := _engine.score(r, _config, WINDOW, false, _inv(CharmQuickDraw.new()))
	assert_almost_eq(bd.charm_mult, 0.0, 0.001, "no bonus when not all in window 1")
	assert_eq(bd.final_score, 18)


func test_quick_draw_no_bonus_when_window2() -> void:
	var r := _result([4, 4], [2, 2])
	var bd := _engine.score(r, _config, WINDOW, false, _inv(CharmQuickDraw.new()))
	assert_almost_eq(bd.charm_mult, 0.0, 0.001)


# --- Loaded -------------------------------------------------------------------

func test_loaded_adds_chips_per_six() -> void:
	# Two sixes → +12 charm_chips; (12 + 10 + 12) × 1 × 1.0 = 34.
	var r := _result([6, 6], [1, 1])
	var bd := _engine.score(r, _config, WINDOW, false, _inv(CharmLoaded.new()))
	assert_eq(bd.charm_chips, 12, "two 6s add 12 charm_chips")
	assert_eq(bd.final_score, 34, "(12 + 10 + 12) x 1 x 1.0 = 34")


func test_loaded_one_six() -> void:
	var r := _result([6, 3], [1, 1])
	var bd := _engine.score(r, _config, WINDOW, false, _inv(CharmLoaded.new()))
	assert_eq(bd.charm_chips, 6, "one 6 adds 6 charm_chips")


func test_loaded_no_bonus_when_no_sixes() -> void:
	var r := _result([4, 4], [1, 1])
	var bd := _engine.score(r, _config, WINDOW, false, _inv(CharmLoaded.new()))
	assert_eq(bd.charm_chips, 0, "no sixes → no charm_chips")
	assert_eq(bd.final_score, 18)


# --- Snake Charmer ------------------------------------------------------------

func test_snake_charmer_replaces_pair_of_1s_scoring() -> void:
	# Standard pair-of-1s: (2 + 10) × 1 × 1.0 = 12.
	# With Snake Charmer: (2 + 0) × 4 × 1.0 = 8.
	var r := _result([1, 1], [1, 1])
	var bd := _engine.score(r, _config, WINDOW, false, _inv(CharmSnakeCharmer.new()))
	assert_eq(bd.combo_mult, 4, "combo_mult replaced with 4")
	assert_eq(bd.bonus_chips, 0, "bonus_chips zeroed")
	assert_eq(bd.final_score, 8, "(2 + 0) x 4 x 1.0 = 8")


func test_snake_charmer_no_effect_on_other_pairs() -> void:
	var r := _result([3, 3], [1, 1])
	var bd := _engine.score(r, _config, WINDOW, false, _inv(CharmSnakeCharmer.new()))
	assert_eq(bd.combo_mult, 1, "non-1 pair not affected")
	assert_eq(bd.bonus_chips, 10)


func test_snake_charmer_no_effect_when_not_pair() -> void:
	# Triple of 1s — the combo is a Triple, not a Pair.
	var r := _result([1, 1, 1], [1, 1, 1])
	var bd := _engine.score(r, _config, WINDOW, false, _inv(CharmSnakeCharmer.new()))
	assert_eq(bd.combo_mult, 2, "triple combo_mult unchanged")
