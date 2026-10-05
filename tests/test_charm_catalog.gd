extends GutTest
## Headless tests for the 9 new charms added in add-12-charms (charm-catalog spec).

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


# --- Hair Trigger (+5 Chips per W1 die) ---------------------------------------

func test_hair_trigger_both_w1() -> void:
	var r := _result([3, 4], [1, 1])
	var bd := _engine.score(r, _config, WINDOW, false, _inv(CharmHairTrigger.new()))
	assert_eq(bd.charm_chips, 10, "two W1 dice = +10 charm_chips")
	assert_eq(bd.final_score, 17, "(7 + 0 + 10) x 1 x 1.0 = 17")


func test_hair_trigger_one_w1_one_w2() -> void:
	var r := _result([3, 4], [1, 2])
	var bd := _engine.score(r, _config, WINDOW, false, _inv(CharmHairTrigger.new()))
	assert_eq(bd.charm_chips, 5, "one W1 die = +5 charm_chips")


func test_hair_trigger_no_w1() -> void:
	var r := _result([3, 4], [2, 3])
	var bd := _engine.score(r, _config, WINDOW, false, _inv(CharmHairTrigger.new()))
	assert_eq(bd.charm_chips, 0, "no W1 dice = no bonus")


# --- Adrenaline (≥3 W1 dice → +1 Mult) ---------------------------------------

func test_adrenaline_three_w1() -> void:
	# Triple of 2s all in W1: pips=6, bonus=30, combo_mult=2, charm_mult=1.0
	# final = floori((6 + 30 + 0) × (2 + 1.0) × 1.0) = 108
	var r := _result([2, 2, 2], [1, 1, 1])
	var bd := _engine.score(r, _config, WINDOW, false, _inv(CharmAdrenaline.new()))
	assert_almost_eq(bd.charm_mult, 1.0, 0.001, "three W1 locks triggers +1 Mult")
	assert_eq(bd.final_score, 108, "(6 + 30 + 0) x (2 + 1.0) x 1.0 = 108")


func test_adrenaline_two_w1_no_bonus() -> void:
	var r := _result([3, 4], [1, 1])
	var bd := _engine.score(r, _config, WINDOW, false, _inv(CharmAdrenaline.new()))
	assert_almost_eq(bd.charm_mult, 0.0, 0.001, "only two W1 = no bonus")


func test_adrenaline_three_dice_only_two_w1() -> void:
	var r := _result([2, 2, 2], [1, 1, 2])
	var bd := _engine.score(r, _config, WINDOW, false, _inv(CharmAdrenaline.new()))
	assert_almost_eq(bd.charm_mult, 0.0, 0.001, "two W1 of three locks = no bonus")


# --- Patient Zero (+5 Chips per W3 die) ---------------------------------------

func test_patient_zero_both_w3() -> void:
	var r := _result([3, 4], [3, 3])
	var bd := _engine.score(r, _config, WINDOW, false, _inv(CharmPatientZero.new()))
	assert_eq(bd.charm_chips, 10, "two W3 dice = +10 charm_chips")
	assert_eq(bd.final_score, 17, "(7 + 0 + 10) x 1 x 1.0 = 17")


func test_patient_zero_one_w3() -> void:
	var r := _result([3, 4], [1, 3])
	var bd := _engine.score(r, _config, WINDOW, false, _inv(CharmPatientZero.new()))
	assert_eq(bd.charm_chips, 5, "one W3 die = +5 charm_chips")


func test_patient_zero_no_w3() -> void:
	var r := _result([3, 4], [1, 2])
	var bd := _engine.score(r, _config, WINDOW, false, _inv(CharmPatientZero.new()))
	assert_eq(bd.charm_chips, 0, "no W3 dice = no bonus")


# --- Ice Cold (no W1 locks → +3 Mult) ----------------------------------------

func test_ice_cold_all_w2_gives_mult() -> void:
	# Pair of 4s in W2: pips=8, bonus=10, combo_mult=1, charm_mult=3.0
	# final = floori((8 + 10 + 0) × (1 + 3.0) × 1.0) = 72
	var r := _result([4, 4], [2, 2])
	var bd := _engine.score(r, _config, WINDOW, false, _inv(CharmIceCold.new()))
	assert_almost_eq(bd.charm_mult, 3.0, 0.001, "no W1 locks → +3 Mult")
	assert_eq(bd.final_score, 72, "(8 + 10 + 0) x (1 + 3.0) x 1.0 = 72")


func test_ice_cold_all_w3_gives_mult() -> void:
	var r := _result([4, 4], [3, 3])
	var bd := _engine.score(r, _config, WINDOW, false, _inv(CharmIceCold.new()))
	assert_almost_eq(bd.charm_mult, 3.0, 0.001, "W3 counts as non-W1 → +3 Mult")


func test_ice_cold_one_w1_no_bonus() -> void:
	var r := _result([4, 4], [1, 2])
	var bd := _engine.score(r, _config, WINDOW, false, _inv(CharmIceCold.new()))
	assert_almost_eq(bd.charm_mult, 0.0, 0.001, "any W1 lock cancels the bonus")


# --- Big Bucks (+3 Chips per locked 5 or 6) -----------------------------------

func test_big_bucks_five_and_six() -> void:
	# [5, 6, 3]: pips=14, no combo, charm_chips=6 → final = 20
	var r := _result([5, 6, 3], [1, 1, 1])
	var bd := _engine.score(r, _config, WINDOW, false, _inv(CharmBigBucks.new()))
	assert_eq(bd.charm_chips, 6, "5 and 6 each add 3 charm_chips")
	assert_eq(bd.final_score, 20, "(14 + 0 + 6) x 1 x 1.0 = 20")


func test_big_bucks_pair_of_fives() -> void:
	# [5, 5]: pips=10, pair bonus=10, charm_chips=6 → final=26
	var r := _result([5, 5], [1, 1])
	var bd := _engine.score(r, _config, WINDOW, false, _inv(CharmBigBucks.new()))
	assert_eq(bd.charm_chips, 6)
	assert_eq(bd.final_score, 26, "(10 + 10 + 6) x 1 x 1.0 = 26")


func test_big_bucks_no_bonus_for_low_faces() -> void:
	var r := _result([1, 2, 3], [1, 1, 1])
	var bd := _engine.score(r, _config, WINDOW, false, _inv(CharmBigBucks.new()))
	assert_eq(bd.charm_chips, 0)


# --- Precision (all same face → +2 Mult) -------------------------------------

func test_precision_triple_same_face() -> void:
	# Triple of 4s: pips=12, bonus=30, combo_mult=2, charm_mult=2.0
	# final = floori((12 + 30 + 0) × (2 + 2.0) × 1.0) = 168
	var r := _result([4, 4, 4], [1, 1, 1])
	var bd := _engine.score(r, _config, WINDOW, false, _inv(CharmPrecision.new()))
	assert_almost_eq(bd.charm_mult, 2.0, 0.001, "all same face → +2 Mult")
	assert_eq(bd.final_score, 168, "(12 + 30 + 0) x (2 + 2.0) x 1.0 = 168")


func test_precision_mixed_faces_no_bonus() -> void:
	var r := _result([4, 4, 3], [1, 1, 1])
	var bd := _engine.score(r, _config, WINDOW, false, _inv(CharmPrecision.new()))
	assert_almost_eq(bd.charm_mult, 0.0, 0.001, "mixed faces = no bonus")


func test_precision_single_die_counts_as_same() -> void:
	# [2]: pips=2, no combo, combo_mult=1, charm_mult=2.0 → final=6
	var r := _result([2], [1])
	var bd := _engine.score(r, _config, WINDOW, false, _inv(CharmPrecision.new()))
	assert_almost_eq(bd.charm_mult, 2.0, 0.001, "single die = trivially all same")
	assert_eq(bd.final_score, 6, "(2 + 0 + 0) x (1 + 2.0) x 1.0 = 6")


# --- Collector (+1 Mult per distinct face) ------------------------------------

func test_collector_three_distinct() -> void:
	# [1, 2, 3]: pips=6, no combo, combo_mult=1, charm_mult=3.0 → final=24
	var r := _result([1, 2, 3], [1, 1, 1])
	var bd := _engine.score(r, _config, WINDOW, false, _inv(CharmCollector.new()))
	assert_almost_eq(bd.charm_mult, 3.0, 0.001, "3 distinct faces → +3 Mult")
	assert_eq(bd.final_score, 24, "(6 + 0 + 0) x (1 + 3.0) x 1.0 = 24")


func test_collector_one_distinct_pair() -> void:
	# [4, 4]: pips=8, pair bonus=10, combo_mult=1, charm_mult=1.0 → final=36
	var r := _result([4, 4], [1, 1])
	var bd := _engine.score(r, _config, WINDOW, false, _inv(CharmCollector.new()))
	assert_almost_eq(bd.charm_mult, 1.0, 0.001, "1 distinct face value → +1 Mult")
	assert_eq(bd.final_score, 36, "(8 + 10 + 0) x (1 + 1.0) x 1.0 = 36")


func test_collector_five_distinct() -> void:
	var r := _result([1, 2, 3, 4, 5], [1, 1, 1, 1, 1])
	var bd := _engine.score(r, _config, WINDOW, false, _inv(CharmCollector.new()))
	assert_almost_eq(bd.charm_mult, 5.0, 0.001, "5 distinct faces → +5 Mult")


# --- High Roller (Quad or Quint → +60 Chips) ----------------------------------

func test_high_roller_quad() -> void:
	# [4, 4, 4, 4]: pips=16, bonus=60, combo_mult=4, charm_chips=60
	# final = floori((16 + 60 + 60) × 4 × 1.0) = 544
	var r := _result([4, 4, 4, 4], [1, 1, 1, 1])
	var bd := _engine.score(r, _config, WINDOW, false, _inv(CharmHighRoller.new()))
	assert_eq(bd.charm_chips, 60, "Quad triggers +60 charm_chips")
	assert_eq(bd.final_score, 544, "(16 + 60 + 60) x 4 x 1.0 = 544")


func test_high_roller_quint() -> void:
	# [5, 5, 5, 5, 5]: pips=25, bonus=100, combo_mult=8, charm_chips=60
	# final = floori((25 + 100 + 60) × 8 × 1.0) = 1480
	var r := _result([5, 5, 5, 5, 5], [1, 1, 1, 1, 1])
	var bd := _engine.score(r, _config, WINDOW, false, _inv(CharmHighRoller.new()))
	assert_eq(bd.charm_chips, 60, "Quint triggers +60 charm_chips")
	assert_eq(bd.final_score, 1480, "(25 + 100 + 60) x 8 x 1.0 = 1480")


func test_high_roller_triple_no_bonus() -> void:
	var r := _result([3, 3, 3], [1, 1, 1])
	var bd := _engine.score(r, _config, WINDOW, false, _inv(CharmHighRoller.new()))
	assert_eq(bd.charm_chips, 0, "Triple does not trigger High Roller")


# --- Straight Edge (Small or Large Straight → +3 Mult) -----------------------

func test_straight_edge_small_straight() -> void:
	# [1, 2, 3, 4]: pips=10, bonus=30, combo_mult=2, charm_mult=3.0
	# final = floori((10 + 30 + 0) × (2 + 3.0) × 1.0) = 200
	var r := _result([1, 2, 3, 4], [1, 1, 1, 1])
	var bd := _engine.score(r, _config, WINDOW, false, _inv(CharmStraightEdge.new()))
	assert_almost_eq(bd.charm_mult, 3.0, 0.001, "Small Straight triggers +3 Mult")
	assert_eq(bd.final_score, 200, "(10 + 30 + 0) x (2 + 3.0) x 1.0 = 200")


func test_straight_edge_large_straight() -> void:
	# [1, 2, 3, 4, 5, 6]: pips=21, bonus=80, combo_mult=5, charm_mult=3.0
	# final = floori((21 + 80 + 0) × (5 + 3.0) × 1.0) = 808
	var r := _result([1, 2, 3, 4, 5, 6], [1, 1, 1, 1, 1, 1])
	var bd := _engine.score(r, _config, WINDOW, false, _inv(CharmStraightEdge.new()))
	assert_almost_eq(bd.charm_mult, 3.0, 0.001, "Large Straight triggers +3 Mult")
	assert_eq(bd.final_score, 808, "(21 + 80 + 0) x (5 + 3.0) x 1.0 = 808")


func test_straight_edge_triple_no_bonus() -> void:
	var r := _result([3, 3, 3], [1, 1, 1])
	var bd := _engine.score(r, _config, WINDOW, false, _inv(CharmStraightEdge.new()))
	assert_almost_eq(bd.charm_mult, 0.0, 0.001, "Triple does not trigger Straight Edge")
