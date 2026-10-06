class_name ScoreHud
extends Control
## Balatro-style score readout (score-cascade spec): CHIPS × MULT × HEAT plaques, the
## target progress bar, floating "+n" numbers, the stamped combo banner and spark
## bursts. Pure presentation: ScoreCascade drives it; it never reads game state.
## Coordinates are in the 1080×2400 base canvas (canvas_items stretch).

const HEAT_COLOR := Color(1.0, 0.56, 0.32)
const STAMP_ANGLE := -0.07
const PLAQUE_RISE := 50.0
## Target bar: the timer kit drawn at half scale (its 9-patch margins need ≥ 52 px height).
const BAR_POS := Vector2(64.0, 212.0)
const BAR_SIZE := Vector2(1904.0, 56.0)
const BAR_FILL_INSET := Vector2(20.0, 10.0)

var chips_label: Label
var mult_label: Label
var heat_label: Label
var stamp_label: Label
var target_fill: NinePatchRect
## Global point the stamp centres on (the tray centre); set by the scene's layout.
var stamp_center := Vector2(540.0, 1100.0)

var _chips_plaque: Panel
var _mult_plaque: Panel
var _heat_plaque: Panel
var _bar: Control
var _transients: Array[Node] = []
## Active floats per spawn cell, so simultaneous floats stack instead of piling up.
var _float_cells := {}
## Running plaque floats: key → { label, value, mult }. Deltas landing on the same
## plaque while its float is alive merge into one number (Hades/VS rule) instead of
## stacking into a pile.
var _sum_floats := {}
## Feedback tunables (stack spacing, stamp hold); the scene may replace it.
var fx: FeedbackConfig = preload("res://resources/feedback_config.tres")


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_chips_plaque = _plaque(Rect2(40, 372, 390, 120))
	chips_label = _value(_chips_plaque, "CHIPS", UiStyle.CREAM, 60)
	_sign("×", Rect2(430, 380, 60, 110))
	_mult_plaque = _plaque(Rect2(490, 372, 310, 120))
	mult_label = _value(_mult_plaque, "MULT", UiStyle.AMBER, 60)
	_sign("×", Rect2(800, 380, 50, 110))
	_heat_plaque = _plaque(Rect2(850, 372, 190, 120))
	heat_label = _value(_heat_plaque, "HEAT", HEAT_COLOR, 44)
	_bar = Control.new()
	_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bar.position = BAR_POS
	_bar.size = BAR_SIZE
	_bar.scale = Vector2(0.5, 0.5)
	add_child(_bar)
	var frame := UiStyle.nine_patch("timer_frame", UiStyle.TIMER_FRAME_MARGINS)
	_bar.add_child(frame)
	frame.position = Vector2.ZERO
	frame.size = BAR_SIZE
	target_fill = UiStyle.nine_patch("timer_fill", UiStyle.TIMER_FILL_MARGINS)
	_bar.add_child(target_fill)
	target_fill.position = BAR_FILL_INSET
	target_fill.size = Vector2(0.0, BAR_SIZE.y - BAR_FILL_INSET.y * 2.0)
	target_fill.visible = false
	stamp_label = Label.new()
	style_stamp(stamp_label)
	stamp_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	stamp_label.visible = false
	add_child(stamp_label)
	reset(1.0)


func _plaque(r: Rect2) -> Panel:
	var p := Panel.new()
	p.theme_type_variation = &"PlaquePanel"
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.position = r.position
	p.size = r.size
	add_child(p)
	return p


func _value(plaque: Panel, caption: String, color: Color, font_size: int) -> Label:
	var cap := Label.new()
	cap.text = caption
	cap.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cap.add_theme_font_size_override("font_size", 22)
	cap.add_theme_color_override("font_color", UiStyle.MUTED)
	cap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	plaque.add_child(cap)
	cap.position = Vector2(0, 6)
	cap.size = Vector2(plaque.size.x, 28)
	var v := Label.new()
	v.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	v.add_theme_font_size_override("font_size", font_size)
	v.add_theme_color_override("font_color", color)
	v.add_theme_color_override("font_outline_color", UiStyle.OUTLINE)
	v.add_theme_constant_override("outline_size", 8)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	plaque.add_child(v)
	v.position = Vector2(0, 26)
	v.size = Vector2(plaque.size.x, plaque.size.y - 30)
	v.pivot_offset = v.size / 2.0
	return v


func _sign(text: String, r: Rect2) -> void:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", 52)
	l.add_theme_color_override("font_color", UiStyle.BRASS)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.position = r.position
	l.size = r.size
	add_child(l)


static func fmt_mult(v: float) -> String:
	return "%d" % roundi(v) if is_equal_approx(v, roundf(v)) else "%.1f" % v


func reset(heat: float) -> void:
	set_chips(0)
	set_mult(0.0)
	set_heat(heat)


func set_chips(v: int) -> void:
	chips_label.text = str(v)


func set_mult(v: float) -> void:
	mult_label.text = fmt_mult(v)


func set_heat(v: float) -> void:
	heat_label.text = "×%.2f" % v


func set_target_fraction(f: float) -> void:
	var w := (BAR_SIZE.x - BAR_FILL_INSET.x * 2.0) * clampf(f, 0.0, 1.0)
	target_fill.visible = w >= float(UiStyle.TIMER_FILL_MARGINS.x * 2)
	target_fill.size.x = w


## Centre of each plaque in global canvas coordinates (float-text origins).
## Float origins sit just above each plaque, so a "+n" never covers the value.
func chips_anchor() -> Vector2:
	return _above(_chips_plaque)


func mult_anchor() -> Vector2:
	return _above(_mult_plaque)


func heat_anchor() -> Vector2:
	return _above(_heat_plaque)


func _above(c: Control) -> Vector2:
	var r := c.get_global_rect()
	return Vector2(r.get_center().x, r.position.y - 36.0)


## Scale pop on a readout (values landing).
func punch(c: CanvasItem, amount: float = 1.35, duration: float = 0.22) -> void:
	if c is Control:
		(c as Control).pivot_offset = (c as Control).size / 2.0
	var t := c.create_tween()
	t.tween_property(c, "scale", Vector2.ONE * amount, duration * 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(c, "scale", Vector2.ONE, duration * 0.7).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


## A "+n" that rises from `at` (global) and fades.
## `rise`: how far it drifts up (px). Plaque floats use a short rise so they stay in
## the status band and never reach the HUD panel; stacked ones never collide.
func float_text(text: String, at: Vector2, color: Color, font_size: int = 64, rise: float = 130.0) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", UiStyle.OUTLINE)
	l.add_theme_constant_override("outline_size", 12)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.size = Vector2(320, 100)
	l.pivot_offset = l.size / 2.0
	add_child(l)
	# Stack: each float already rising from this spot pushes the new one up a row.
	var cell := Vector2i(roundi(at.x / 80.0), roundi(at.y / 80.0))
	var stacked: int = _float_cells.get(cell, 0)
	_float_cells[cell] = stacked + 1
	l.set_meta(&"cell", cell)
	l.global_position = at - l.size / 2.0 - Vector2(0.0, fx.float_stack_px * stacked)
	l.scale = Vector2(0.4, 0.4)
	_transients.append(l)
	_float_motion(l, rise)
	return l


func _float_motion(l: Label, rise: float) -> void:
	if l.has_meta(&"tween"):
		var old: Tween = l.get_meta(&"tween")
		if old != null and old.is_valid():
			old.kill()
	l.modulate.a = 1.0
	var t := l.create_tween()
	t.tween_property(l, "scale", Vector2.ONE * 1.15, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.parallel().tween_property(l, "position:y", l.position.y - rise, 0.75).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.tween_property(l, "modulate:a", 0.0, 0.25)
	t.tween_callback(_drop.bind(l))
	l.set_meta(&"tween", t)


## A plaque delta ("+30" chips, "+2" mult). While the plaque's float is still alive,
## new deltas add into it and it re-punches, so a run of charm triggers reads as one
## climbing number rather than a stack.
func float_sum(key: StringName, delta: float, at: Vector2, is_mult: bool, suffix: String = "") -> Label:
	var e: Dictionary = _sum_floats.get(key, {})
	if not e.is_empty() and is_instance_valid(e.label) and not (e.label as Label).is_queued_for_deletion():
		e.value = float(e.value) + delta
		var l: Label = e.label
		l.text = _sum_text(float(e.value), is_mult, suffix)
		l.add_theme_color_override("font_color", _sum_color(float(e.value), is_mult))
		l.scale = Vector2(0.8, 0.8)
		_float_motion(l, PLAQUE_RISE * 0.4)
		return l
	var nl := float_text(_sum_text(delta, is_mult, suffix), at, _sum_color(delta, is_mult), 64, PLAQUE_RISE)
	_sum_floats[key] = {"label": nl, "value": delta}
	return nl


static func _sum_text(v: float, is_mult: bool, suffix: String) -> String:
	var core := (("+" if v > 0.0 else "") + fmt_mult(v)) if is_mult else ("%+d" % roundi(v))
	return core + (" " + suffix if suffix != "" else "")


static func _sum_color(v: float, is_mult: bool) -> Color:
	if v < 0.0:
		return Color(0.85, 0.35, 0.3)
	return UiStyle.AMBER if is_mult else UiStyle.CREAM


func active_floats_at(at: Vector2) -> int:
	return _float_cells.get(Vector2i(roundi(at.x / 80.0), roundi(at.y / 80.0)), 0)


## The combo name slams onto the table: oversized, tilted, settling with a bounce.
func stamp(text: String) -> void:
	stamp_label.text = text.to_upper()
	stamp_label.size = Vector2(1000, 360)
	stamp_label.pivot_offset = stamp_label.size / 2.0
	stamp_label.global_position = stamp_center - stamp_label.size / 2.0
	stamp_label.rotation = STAMP_ANGLE
	stamp_label.modulate = Color(1, 1, 1, 0)
	stamp_label.visible = true
	var t := slam(stamp_label)
	# Then it lifts off the dice so the board can be read: up, smaller, fading.
	t.tween_interval(fx.stamp_hold_s)
	t.tween_property(stamp_label, "position:y", stamp_label.position.y - 220.0, 0.3) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	t.parallel().tween_property(stamp_label, "scale", Vector2.ONE * 0.55, 0.3)
	t.parallel().tween_property(stamp_label, "modulate:a", 0.0, 0.3)
	t.tween_callback(stamp_label.hide)


func clear_stamp() -> void:
	if not stamp_label.visible:
		return
	var t := stamp_label.create_tween()
	t.tween_property(stamp_label, "modulate:a", 0.0, 0.2)
	t.tween_callback(stamp_label.hide)


## Brass-spark burst at `at` (global); `amount` scales with the combo tier.
func burst(at: Vector2, amount: int) -> void:
	var p := spawn_burst(self, at, amount)
	if p != null:
		_transients.append(p)
		p.tree_exiting.connect(_transients.erase.bind(p))  # it frees itself when done


## A one-shot spark burst under any parent (the end panel reuses it); frees itself.
static func spawn_burst(parent: Node, at: Vector2, amount: int) -> CPUParticles2D:
	if amount <= 0:
		return null
	var p := CPUParticles2D.new()
	p.texture = spark_texture()
	p.amount = amount
	p.one_shot = true
	p.explosiveness = 0.95
	p.lifetime = 0.9
	p.direction = Vector2.UP
	p.spread = 180.0
	p.initial_velocity_min = 380.0
	p.initial_velocity_max = 900.0
	p.gravity = Vector2(0, 1400)
	p.damping_min = 40.0
	p.damping_max = 120.0
	p.scale_amount_min = 0.4
	p.scale_amount_max = 1.3
	var ramp := Gradient.new()
	ramp.set_color(0, Color(1.0, 0.95, 0.7, 1.0))
	ramp.set_color(1, Color(1.0, 0.45, 0.08, 0.0))
	p.color_ramp = ramp
	parent.add_child(p)
	p.global_position = at
	p.emitting = true
	p.finished.connect(p.queue_free)
	return p


static var _spark_tex: Texture2D


static func spark_texture() -> Texture2D:
	if _spark_tex == null:
		var g := Gradient.new()
		g.set_color(0, Color(1, 1, 1, 1))
		g.set_color(1, Color(1, 1, 1, 0))
		var gt := GradientTexture2D.new()
		gt.gradient = g
		gt.fill = GradientTexture2D.FILL_RADIAL
		gt.fill_from = Vector2(0.5, 0.5)
		gt.fill_to = Vector2(0.5, 0.0)
		gt.width = 32
		gt.height = 32
		_spark_tex = gt
	return _spark_tex


## Big tilted stamp text in the HUD style (combo banner, end-of-run title).
static func style_stamp(l: Label, font_size: int = 120, color: Color = UiStyle.AMBER) -> void:
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", UiStyle.OUTLINE)
	l.add_theme_constant_override("outline_size", 22)
	l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	l.add_theme_constant_override("shadow_offset_x", 6)
	l.add_theme_constant_override("shadow_offset_y", 9)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE


## Slam a label in: oversized and transparent → settles with a small bounce.
static func slam(l: Control, from_scale: float = 2.6) -> Tween:
	l.pivot_offset = l.size / 2.0
	l.scale = Vector2.ONE * from_scale
	l.modulate.a = 0.0
	var t := l.create_tween()
	t.tween_property(l, "scale", Vector2.ONE, 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	t.parallel().tween_property(l, "modulate:a", 1.0, 0.1)
	t.tween_property(l, "scale", Vector2.ONE * 1.08, 0.08)
	t.tween_property(l, "scale", Vector2.ONE, 0.12)
	return t


func clear_transients() -> void:
	for n in _transients:
		if is_instance_valid(n):
			n.queue_free()
	_transients.clear()
	_float_cells.clear()
	_sum_floats.clear()
	stamp_label.visible = false


func transient_count() -> int:
	var n := 0
	for t in _transients:
		if is_instance_valid(t) and not t.is_queued_for_deletion():
			n += 1
	return n


func _drop(n: Node) -> void:
	_transients.erase(n)
	if is_instance_valid(n) and n.has_meta(&"cell"):
		var cell: Vector2i = n.get_meta(&"cell")
		_float_cells[cell] = maxi(0, int(_float_cells.get(cell, 1)) - 1)
	if is_instance_valid(n):
		n.queue_free()
