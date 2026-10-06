class_name ScoreCascade
extends RefCounted
## Animated score reveal played after every throw resolution (score-cascade spec).
## Owns the Tween chain: die flash → combo label pop → score tick → total tick.
## Call skip() to resolve instantly (headless tests, balance sim).

signal finished
## A charm whose on_score changed this throw (breakdown.charm_triggers), in slot order.
signal charm_triggered(slot: int)

const COLOR_FLASH := Color(1.0, 0.82, 0.2)
const CHARM_PULSE_GAP_S := 0.18

## Exposed so the scene can read the final score after the cascade completes.
var final_score: int = 0

var _tween: Tween
var _scene: Node
var _tumbler: DiceTumbler
var _result_label: Label
var _total_label: Label
var _config: ScoringConfig
var _old_total: int = 0
var _new_total: int = 0
var _target: int = 0


func _init(p_scene: Node, p_tumbler: DiceTumbler, p_result: Label,
		p_total: Label, p_config: ScoringConfig) -> void:
	_scene = p_scene
	_tumbler = p_tumbler
	_result_label = p_result
	_total_label = p_total
	_config = p_config


func play(breakdown: ScoreBreakdown, old_total: int, new_total: int,
		target: int) -> void:
	final_score = breakdown.final_score
	_old_total = old_total
	_new_total = new_total
	_target = target

	# Collect locked die indices from the chosen partition (dedup).
	var locked_indices: Array[int] = []
	for combo in breakdown.combos:
		for idx: int in combo.dice_indices:
			if not locked_indices.has(idx):
				locked_indices.append(idx)

	# Prime the combo label: invisible, correct text, pivot centred.
	var parts: Array[String] = []
	for combo in breakdown.combos:
		parts.append(combo.name)
	var combo_text: String = "No score" if parts.is_empty() else " + ".join(parts)
	var sz := _result_label.size  # read before text change; falls back to 0,0 on first throw
	_result_label.text = combo_text
	_result_label.pivot_offset = sz / 2.0 if sz != Vector2.ZERO else Vector2(500.0, 125.0)
	_result_label.scale = Vector2.ZERO

	_tween = _scene.create_tween()
	_tween.set_parallel(false)

	# Step 1: flash locked dice gold → back to green, sequentially.
	var flash_dur := 0.15
	for idx in locked_indices:
		_tween.tween_callback(_tumbler.flash_die.bind(idx, COLOR_FLASH, flash_dur))
		_tween.tween_interval(flash_dur)

	# Step 2: combo label scales in from 0 (BACK ease gives a slight overshoot).
	_tween.tween_property(_result_label, "scale", Vector2.ONE, 0.2) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	# Step 2b: each charm that changed the score announces itself (slot pulse).
	for trig in breakdown.charm_triggers:
		_tween.tween_callback(charm_triggered.emit.bind(int(trig.slot)))
		_tween.tween_interval(CHARM_PULSE_GAP_S)

	# Step 3: throw score ticks from 0 to final_score.
	_tween.tween_method(_tick_score, 0.0, float(final_score),
		_config.cascade_duration_s) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	# Step 4: round total ticks to new value.
	_tween.tween_method(_tick_total, float(_old_total), float(_new_total), 0.3) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	_tween.tween_callback(finished.emit)


## Immediately resolves the cascade to final state. Safe to call at any point.
func skip() -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tick_score(float(final_score))
	_tick_total(float(_new_total))
	if is_instance_valid(_result_label):
		_result_label.scale = Vector2.ONE
	finished.emit()


func _tick_score(value: float) -> void:
	if is_instance_valid(_result_label):
		_result_label.text = "%d pts" % roundi(value)


func _tick_total(value: float) -> void:
	if is_instance_valid(_total_label):
		_total_label.text = "Total: %d / %d" % [roundi(value), _target]
