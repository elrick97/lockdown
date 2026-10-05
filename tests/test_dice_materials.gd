extends GutTest
## Headless tests for dice material pip adjustments (dice-materials spec).

const WINDOW := 2.5

var _config: ScoringConfig
var _engine: ScoringEngine


func before_each() -> void:
	_config = ScoringConfig.new()
	_engine = ScoringEngine.new()


func _result(faces: Array, pip_offsets: Array = [], pip_multipliers: Array = [], shattered: Array = []) -> ThrowResult:
	var r := ThrowResult.new()
	for f in faces:
		r.faces.append(int(f))
		r.locked_order.append(r.faces.size() - 1)
		r.lock_windows.append(1)
	for v in pip_offsets:
		r.pip_offsets.append(int(v))
	for v in pip_multipliers:
		r.pip_multipliers.append(int(v))
	for v in shattered:
		r.shattered.append(bool(v))
	return r


# --- Iron (-1 pip offset) ---

func test_iron_pip_offset_reduces_pips() -> void:
	# Iron die showing 4: (4 + (-1)) * 1 = 3 pips. No combo → score = 3.
	var r := _result([4], [-1], [1])
	var bd := _engine.score(r, _config, WINDOW)
	assert_eq(bd.pips, 3, "Iron 4 → 3 pips")
	assert_eq(bd.final_score, 3, "no combo: 3 × 1 × 1.0 = 3")


func test_iron_face_unchanged_for_combos() -> void:
	# Two Iron dice showing face 6: still a Pair (face 6 matches face 6).
	# Pips: (6-1)*1 + (6-1)*1 = 10. Pair bonus = 10. combo_mult = 1.
	# final = (10 + 10) × 1 × 1.0 = 20
	var r := _result([6, 6], [-1, -1], [1, 1])
	var bd := _engine.score(r, _config, WINDOW)
	assert_eq(bd.pips, 10, "two Iron 6s → 10 pips (5 + 5)")
	assert_false(bd.combos.is_empty(), "Iron pair still detected")
	assert_eq(bd.combos[0].name, "Pair")
	assert_eq(bd.final_score, 20, "(10 + 10) × 1 × 1.0 = 20")


func test_iron_min_zero_pip() -> void:
	# Iron die showing 1: max(0, 1 + (-1)) = 0 pips.
	var r := _result([1], [-1], [1])
	var bd := _engine.score(r, _config, WINDOW)
	assert_eq(bd.pips, 0, "Iron 1 → 0 pips (clamped)")


# --- Glass (×2 pip multiplier) ---

func test_glass_pip_multiplier_doubles_pips() -> void:
	# Glass die showing 5: (5 + 0) × 2 = 10 pips.
	var r := _result([5], [0], [2])
	var bd := _engine.score(r, _config, WINDOW)
	assert_eq(bd.pips, 10, "Glass 5 → 10 pips")


func test_glass_pair_combo_detected() -> void:
	# Two Glass dice showing 3: combo Pair still detected (face value unchanged).
	# Pips: 3*2 + 3*2 = 12. Pair bonus = 10. combo_mult = 1.
	# final = (12 + 10) × 1 × 1.0 = 22
	var r := _result([3, 3], [0, 0], [2, 2])
	var bd := _engine.score(r, _config, WINDOW)
	assert_eq(bd.pips, 12, "Glass pair-of-3s → 12 pips")
	assert_eq(bd.combos[0].name, "Pair")
	assert_eq(bd.final_score, 22, "(12 + 10) × 1 × 1.0 = 22")


# --- Glass shatter ---

func test_shattered_die_excluded_from_scoring() -> void:
	# Two dice: Glass die (shattered) + Bone die showing 4.
	# Only Bone die scores: 4 pips, no combo. final = 4.
	var r := _result([6, 4], [0, 0], [2, 1], [true, false])
	var bd := _engine.score(r, _config, WINDOW)
	assert_eq(bd.pips, 4, "shattered Glass die excluded; only Bone 4 = 4 pips")
	assert_true(bd.combos.is_empty(), "no combo when high die is shattered")
	assert_eq(bd.final_score, 4)


func test_all_shattered_zero_score() -> void:
	var r := _result([6, 6], [0, 0], [2, 2], [true, true])
	var bd := _engine.score(r, _config, WINDOW)
	assert_eq(bd.final_score, 0, "all shattered → score 0")
