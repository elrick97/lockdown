class_name CoachMark
extends PanelContainer
## First-time tip bubble (ui-theme spec, add-first-time-tips): a leather plaque with
## one line, placed above (or below) the element it explains, with a brass pointer.
## It never takes input: any tap dismisses it and still reaches what's underneath.

const WIDTH := 860.0
const AUTO_HIDE_S := 6.0

var label: Label
var _pointer: Polygon2D
var _timer: SceneTreeTimer


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	theme_type_variation = &"PlaquePanel"
	custom_minimum_size = Vector2(WIDTH, 0.0)
	visible = false
	z_index = 12
	label = Label.new()
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.custom_minimum_size.x = WIDTH - 80.0
	label.add_theme_font_size_override("font_size", 38)
	label.add_theme_color_override("font_color", UiStyle.CREAM)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(label)
	_pointer = Polygon2D.new()
	_pointer.color = UiStyle.BRASS
	add_child(_pointer)


## Show `text` next to `target` (global rect): above it if there's room, else below.
func show_tip(text: String, target: Rect2) -> void:
	label.text = text
	visible = true
	reset_size()
	var vp := get_viewport_rect().size
	var above := target.position.y - size.y - 40.0 > 120.0
	var y := target.position.y - size.y - 34.0 if above else target.end.y + 34.0
	var x := clampf(target.get_center().x - size.x * 0.5, 30.0, vp.x - size.x - 30.0)
	global_position = Vector2(x, clampf(y, 20.0, vp.y - size.y - 20.0))
	var px := clampf(target.get_center().x - global_position.x, 40.0, size.x - 40.0)
	_pointer.polygon = PackedVector2Array([Vector2(px - 22, size.y), Vector2(px + 22, size.y), Vector2(px, size.y + 26)]) \
		if above else PackedVector2Array([Vector2(px - 22, 0), Vector2(px + 22, 0), Vector2(px, -26)])
	modulate.a = 0.0
	var t := create_tween()
	t.tween_property(self, "modulate:a", 1.0, 0.18)
	_timer = get_tree().create_timer(AUTO_HIDE_S)
	_timer.timeout.connect(_auto_hide.bind(_timer))


func _auto_hide(which: SceneTreeTimer) -> void:
	if which == _timer:
		visible = false


func _input(event: InputEvent) -> void:
	if visible and event is InputEventMouseButton and (event as InputEventMouseButton).pressed:
		visible = false  # not consumed: the tap still locks the die / presses the button
