extends GutTest
## heat spec scenarios.

const WINDOW := 2.5  # lock_window_duration_s default

var _config: ScoringConfig


func before_each() -> void:
	_config = ScoringConfig.new()


func test_maximum_speed() -> void:
	# All three windows credited at full duration → heat_max.
	var heat := Heat.from_remaining([WINDOW, WINDOW, WINDOW], _config, WINDOW)
	assert_almost_eq(heat, _config.heat_max, 0.0001)


func test_slowest_play() -> void:
	var heat := Heat.from_remaining([0.0, 0.0, 0.0], _config, WINDOW)
	assert_almost_eq(heat, _config.heat_min, 0.0001)


func test_midpoint() -> void:
	# Half of total_possible (7.5s) → exactly halfway up the curve.
	var heat := Heat.from_remaining([1.25, 1.25, 1.25], _config, WINDOW)
	assert_almost_eq(heat, 1.25, 0.0001)


func test_identical_inputs_identical_heat() -> void:
	var a := Heat.from_remaining([0.7, 1.1, 0.0], _config, WINDOW)
	var b := Heat.from_remaining([0.7, 1.1, 0.0], _config, WINDOW)
	assert_eq(a, b)


func test_steady_mode_returns_constant() -> void:
	assert_almost_eq(Heat.steady(_config), _config.steady_heat, 0.0001)
	assert_almost_eq(Heat.steady(_config), 1.25, 0.0001)
