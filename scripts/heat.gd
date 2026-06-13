class_name Heat
extends RefCounted
## Time-remaining → multiplier conversion (heat spec). Pure and deterministic:
## derives only from the recorded window times, so it is frame-rate and device
## independent. Separate from the scoring engine so the M0 dilemma tuning — which
## is only about this curve — lives in one isolated, well-tested unit.


## Normal Heat: total remaining time mapped linearly onto [heat_min, heat_max].
static func from_remaining(window_remaining_s: Array, config: ScoringConfig, window_duration: float) -> float:
	var total := 0.0
	for t in window_remaining_s:
		total += t
	var possible := window_remaining_s.size() * window_duration
	var fraction := 0.0 if possible <= 0.0 else clampf(total / possible, 0.0, 1.0)
	return config.heat_min + (config.heat_max - config.heat_min) * fraction


## Steady Mode: fixed population-average constant, independent of timing
## (PRD §4.6). The seam exists in M0; the UI to enable it arrives in M2.
static func steady(config: ScoringConfig) -> float:
	return config.steady_heat
