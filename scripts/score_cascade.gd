class_name ScoreCascade
extends RefCounted
## Animated score reveal played after every throw resolution (score-cascade spec).
## The breakdown plays out as steps on the CHIPS × MULT × HEAT plaques: each scoring
## die adds its pips, the combo stamps in (shake + sparks by tier) and adds its chips
## and mult, triggered charms pulse and add theirs, Heat multiplies, then the throw
## score ticks up and pours into the round total. What is shown sums to what is scored.
## Call skip() to resolve instantly (headless tests, balance sim).

signal finished
## A charm whose on_score changed this throw (breakdown.charm_triggers), in slot order.
signal charm_triggered(slot: int)
## Screen shake request (the scene owns the shake).
signal shake_requested(amplitude_px: float, duration_s: float)
signal target_hit

const COLOR_FLASH := Color(1.0, 0.82, 0.2)
const COLOR_MINUS := Color(0.85, 0.35, 0.3)

## Exposed so the scene can read the final score after the cascade completes.
var final_score: int = 0

var _tween: Tween
var _scene: Node
var _tumbler: DiceTumbler
var _hud: ScoreHud
var _result_label: Label
var _total_label: Label
var _config: ScoringConfig
var _fx: FeedbackConfig
var _steps: Array = []
var _heat: float = 1.0
var _chips: int = 0
var _mult: float = 0.0
var _old_total: int = 0
var _new_total: int = 0
var _target: int = 0
var _done := false
var _started_ms: int = -1


func _init(p_scene: Node, p_tumbler: DiceTumbler, p_hud: ScoreHud, p_result: Label,
		p_total: Label, p_config: ScoringConfig, p_fx: FeedbackConfig) -> void:
	_scene = p_scene
	_tumbler = p_tumbler
	_hud = p_hud
	_result_label = p_result
	_total_label = p_total
	_config = p_config
	_fx = p_fx


## The breakdown as display steps. Pure: summing every step's chips gives
## pips + bonus_chips + charm_chips, and its mult gives combo_mult + charm_mult.
## Balatro order: the hand's base (combo chips × mult, already previewed while
## locking) stamps first, then dice add pips, then Gem, charms and Heat.
static func build_steps(bd: ScoreBreakdown, base_mult: int) -> Array:
	var steps: Array = []
	var base := combo_base(bd, base_mult)
	var names: Array[String] = []
	for c in bd.combos:
		names.append(c.name)
	if names.is_empty():
		steps.append({"kind": &"base", "chips": int(base.chips), "mult": float(base.mult)})
	else:
		steps.append({"kind": &"stamp", "text": " + ".join(names),
			"chips": int(base.chips), "mult": float(base.mult)})
	for d in bd.die_pips:
		steps.append({"kind": &"die", "idx": int(d.idx), "chips": int(d.pips), "mult": 0.0})
	if bd.gem_chips != 0:
		steps.append({"kind": &"gem", "chips": bd.gem_chips, "mult": 0.0})
	for t in bd.charm_triggers:
		steps.append({"kind": &"charm", "slot": int(t.slot), "chips": int(t.chips), "mult": float(t.mult)})
	steps.append({"kind": &"heat", "chips": 0, "mult": 0.0})
	return steps


## The hand's base before dice and charms: combo chips and mult (base_mult when no
## combo). This is what the live lock preview shows (throw-loop spec).
static func combo_base(bd: ScoreBreakdown, base_mult: int) -> Dictionary:
	var chips := 0
	var mult := 0
	for c in bd.combos:
		chips += int(c.chips)
		mult += int(c.mult)
	return {"chips": chips, "mult": maxi(mult, base_mult)}


static func sum_steps(steps: Array) -> Dictionary:
	var chips := 0
	var mult := 0.0
	for s in steps:
		chips += int(s.chips)
		mult += float(s.mult)
	return {"chips": chips, "mult": mult}


func play(breakdown: ScoreBreakdown, old_total: int, new_total: int, target: int) -> void:
	final_score = breakdown.final_score
	_old_total = old_total
	_new_total = new_total
	_target = target
	_heat = breakdown.heat
	_steps = build_steps(breakdown, _config.base_mult)
	_chips = 0
	_mult = 0.0
	_hud.clear_transients()
	_hud.reset(_heat)
	_result_label.text = ""
	_result_label.scale = Vector2.ONE
	var tier := FeedbackConfig.tier_of(breakdown)

	_started_ms = Time.get_ticks_msec()
	_tween = _scene.create_tween()
	_tween.set_parallel(false)
	for step in _steps:
		_tween.tween_callback(_apply.bind(step, tier))
		_tween.tween_interval(_step_s(step))

	# The product slams into the throw score; bigger scores tick longer.
	_tween.tween_method(_tick_score, 0.0, float(final_score), _fx.tick_s(final_score, _config.cascade_duration_s)) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_tween.tween_callback(_land)
	_tween.tween_interval(0.15)

	# Then it pours into the round total and the target bar.
	_tween.tween_method(_tick_total, float(_old_total), float(_new_total), _fx.total_pour_s) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	if _target > 0 and _old_total < _target and _new_total >= _target:
		_tween.tween_callback(_target_hit)
		_tween.tween_interval(_fx.target_hit_s)
	_tween.tween_callback(_finish)


## True while the cascade is animating (between play() and finished).
func is_playing() -> bool:
	return _started_ms >= 0 and not _done


## Seconds since play() started (tap-to-skip grace).
func elapsed_s() -> float:
	return 0.0 if _started_ms < 0 else (Time.get_ticks_msec() - _started_ms) / 1000.0


## Immediately resolves the cascade to final state. Safe to call at any point.
func skip() -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
	var sums := sum_steps(_steps)
	if is_instance_valid(_hud):
		_hud.clear_transients()
		_hud.set_chips(int(sums.chips))
		_hud.set_mult(float(sums.mult))
		_hud.set_heat(_heat)
	_tick_score(float(final_score))
	_tick_total(float(_new_total))
	if is_instance_valid(_result_label):
		_result_label.scale = Vector2.ONE
	_finish()


func _step_s(step: Dictionary) -> float:
	match step.kind:
		&"die": return _fx.die_step_s
		&"stamp": return _fx.stamp_s
		&"gem": return _fx.combo_step_s
		&"base": return _fx.combo_step_s * 0.5
		&"charm": return _fx.charm_pulse_gap_s
		&"heat": return _fx.heat_step_s
	return 0.0


func _apply(step: Dictionary, tier: int) -> void:
	if not is_instance_valid(_hud):
		return
	match step.kind:
		&"die":
			var idx: int = step.idx
			_tumbler.flash_die(idx, COLOR_FLASH, _fx.die_step_s * 1.6)
			_tumbler.punch_die(idx, _fx.lock_punch_scale, _fx.lock_punch_s)
			var r := _tumbler.die_rect(idx)
			var at := r.get_center() if r.size != Vector2.ZERO else _hud.chips_anchor()
			_hud.float_text("+%d" % int(step.chips), at, UiStyle.CREAM)
		&"stamp", &"base":
			if step.kind == &"stamp":
				_hud.stamp(step.text)
				shake_requested.emit(_fx.shake_px_by_tier[tier], _fx.shake_s_by_tier[tier])
				_hud.burst(_hud.stamp_center, _fx.sparks_by_tier[tier])
			# The plaques usually show this base already (live preview); float only
			# what changed, e.g. after window 3 force-locked more dice.
			var shown_chips := int(_hud.chips_label.text) if _hud.chips_label.text.is_valid_int() else 0
			var shown_mult := float(_hud.mult_label.text) if _hud.mult_label.text.is_valid_float() else 0.0
			_float_delta({"chips": int(step.chips) - shown_chips, "mult": float(step.mult) - shown_mult}, "")
		&"gem":
			_float_delta(step, "GEM")
		&"charm":
			charm_triggered.emit(int(step.slot))
			_float_delta(step, "")
		&"heat":
			_hud.punch(_hud.heat_label, 1.5, 0.3)
			_hud.float_text("×%.2f" % _heat, _hud.heat_anchor(), ScoreHud.HEAT_COLOR, 56)
	_chips += int(step.chips)
	_mult += float(step.mult)
	_hud.set_chips(_chips)
	_hud.set_mult(_mult)
	if int(step.chips) != 0:
		_hud.punch(_hud.chips_label)
	if not is_zero_approx(float(step.mult)):
		_hud.punch(_hud.mult_label)


func _float_delta(step: Dictionary, suffix: String) -> void:
	var c := int(step.chips)
	var m := float(step.mult)
	if c != 0:
		var txt := ("+%d" % c if c > 0 else "%d" % c) + (" " + suffix if suffix != "" else "")
		_hud.float_text(txt, _hud.chips_anchor(), UiStyle.CREAM if c > 0 else COLOR_MINUS)
	if not is_zero_approx(m):
		var txt := ("+" if m > 0.0 else "") + ScoreHud.fmt_mult(m)
		_hud.float_text(txt, _hud.mult_anchor(), UiStyle.AMBER if m > 0.0 else COLOR_MINUS)


func _land() -> void:
	if is_instance_valid(_result_label):
		_hud.punch(_result_label, 1.4, 0.3)


func _target_hit() -> void:
	target_hit.emit()
	if not is_instance_valid(_hud):
		return
	var tier := clampi(_fx.target_hit_tier, 0, _fx.shake_px_by_tier.size() - 1)
	_hud.stamp("TARGET HIT!")
	_hud.burst(_hud.stamp_center, _fx.sparks_by_tier[tier])
	_hud.punch(_hud.target_fill, 1.0, 0.1)
	shake_requested.emit(_fx.shake_px_by_tier[tier], _fx.shake_s_by_tier[tier])


func _finish() -> void:
	if _done:
		return
	_done = true
	if is_instance_valid(_hud):
		_hud.clear_stamp()
	finished.emit()


func _tick_score(value: float) -> void:
	if is_instance_valid(_result_label):
		_result_label.text = "%d pts" % roundi(value)


func _tick_total(value: float) -> void:
	if is_instance_valid(_total_label):
		_total_label.text = "Total: %d / %d" % [roundi(value), _target]
	if is_instance_valid(_hud) and _target > 0:
		_hud.set_target_fraction(value / float(_target))
