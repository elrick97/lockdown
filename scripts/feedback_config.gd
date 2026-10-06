class_name FeedbackConfig
extends Resource
## Score-feedback tunables (score-cascade + throw-loop specs). Presentation only: none
## of these touch scoring, Heat or window timing.

## Seconds per step of the Chips × Mult build-up.
@export var die_step_s: float = 0.16
@export var stamp_s: float = 0.34
@export var combo_step_s: float = 0.32
@export var charm_pulse_gap_s: float = 0.18
@export var heat_step_s: float = 0.36
## Throw-score tick: cascade_duration_s (ScoringConfig) × (tick_base + tick_per_decade × log10(score + 1)),
## capped at tick_max_s, so bigger scores tick longer.
@export var tick_base: float = 0.5
@export var tick_per_decade: float = 0.25
@export var tick_max_s: float = 1.6
@export var total_pour_s: float = 0.45
@export var target_hit_s: float = 0.9
## Combo tier 0–5 (none, Pair/Two Pair, Triple/Small Straight, Full House,
## Quad/Large Straight, Quint) → shake amplitude, shake duration, spark count.
@export var shake_px_by_tier: PackedFloat32Array = [0.0, 6.0, 10.0, 16.0, 24.0, 34.0]
@export var shake_s_by_tier: PackedFloat32Array = [0.0, 0.22, 0.28, 0.36, 0.48, 0.6]
@export var sparks_by_tier: PackedInt32Array = [0, 10, 18, 30, 48, 80]
@export var target_hit_tier: int = 3
## Lock feedback: die scale pop and a tiny shake.
@export var lock_punch_scale: float = 1.18
@export var lock_punch_s: float = 0.18
@export var lock_shake_px: float = 3.0
@export var lock_shake_s: float = 0.1
## Timer urgency: the last urgency_s of a window pulses toward oxblood.
@export var urgency_s: float = 0.8


static func tier_of(breakdown: ScoreBreakdown) -> int:
	var tier := 0
	for c in breakdown.combos:
		tier = maxi(tier, tier_of_type(int(c.type)))
	return tier


static func tier_of_type(type: int) -> int:
	match type:
		ScoringConfig.ComboType.PAIR, ScoringConfig.ComboType.TWO_PAIR: return 1
		ScoringConfig.ComboType.TRIPLE, ScoringConfig.ComboType.SMALL_STRAIGHT: return 2
		ScoringConfig.ComboType.FULL_HOUSE: return 3
		ScoringConfig.ComboType.QUAD, ScoringConfig.ComboType.LARGE_STRAIGHT: return 4
		ScoringConfig.ComboType.QUINT: return 5
	return 0


func tick_s(score: int, cascade_duration_s: float) -> float:
	var t := cascade_duration_s * (tick_base + tick_per_decade * log(float(score) + 1.0) / log(10.0))
	return minf(t, tick_max_s)
