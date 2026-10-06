extends Control
## Start screen (run-flow spec): pictogram mark (no name or logo until PRD Q4), a
## four-line how-to, and PLAY in the thumb zone. Layout is set in code: hand-authored
## scene anchors don't survive the Android export (see project notes).

const THROW_SCENE := "res://scenes/throw/throw_scene.tscn"
const BRASS := UiStyle.BRASS
const AMBER := UiStyle.AMBER
const HOW_TO := [
	"Throw, then tap dice to lock them.",
	"Lock before the timer empties: the rest re-roll.",
	"Only locked dice score. Make combos.",
	"Lock fast: speed heats up your score.",
]

var _mark: Control
var _how_to: Label
var _play_button: Button
var _how_to_card: Panel


func _ready() -> void:
	theme = UiStyle.theme()
	SmokeOverlay.add_backdrop(self)
	SmokeOverlay.add_to(self)

	_mark = Control.new()
	_mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_mark.draw.connect(_draw_mark)
	add_child(_mark)

	_how_to_card = Panel.new()
	_how_to_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_how_to_card)
	_how_to = Label.new()
	_how_to.text = "\n".join(HOW_TO)
	_how_to.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_how_to.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_how_to.add_theme_font_size_override("font_size", 46)
	_how_to.add_theme_constant_override("line_spacing", 18)
	add_child(_how_to)

	_play_button = Button.new()
	_play_button.text = "PLAY"
	_play_button.theme_type_variation = &"ThrowButton"
	_play_button.pressed.connect(_on_play_pressed)
	add_child(_play_button)

	_apply_layout()
	get_viewport().size_changed.connect(_apply_layout)


func _apply_layout() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_place(_mark, 0.5, 0.0, 0.5, 0.0, -220.0, 300.0, 220.0, 740.0)
	_place(_how_to_card, 0.0, 0.0, 1.0, 0.0, 50.0, 860.0, -50.0, 1500.0)
	_place(_how_to, 0.0, 0.0, 1.0, 0.0, 100.0, 900.0, -100.0, 1460.0)
	_place(_play_button, 0.5, 1.0, 0.5, 1.0, -280.0, -420.0, 280.0, -200.0)
	_mark.queue_redraw()


func _place(c: Control, al: float, at: float, ar: float, ab: float,
		ol: float, ot: float, orr: float, ob: float) -> void:
	c.anchor_left = al
	c.anchor_top = at
	c.anchor_right = ar
	c.anchor_bottom = ab
	c.offset_left = ol
	c.offset_top = ot
	c.offset_right = orr
	c.offset_bottom = ob


## Die outline with five pips, crossed by a bolt: brass and amber line art.
func _draw_mark() -> void:
	var s := _mark.size
	var die := Rect2(s * Vector2(0.08, 0.12), s * Vector2(0.62, 0.62))
	_mark.draw_rect(die, BRASS, false, 10.0)
	var pip_r := die.size.x * 0.07
	for p: Vector2 in [Vector2(0.25, 0.25), Vector2(0.75, 0.25), Vector2(0.5, 0.5),
			Vector2(0.25, 0.75), Vector2(0.75, 0.75)]:
		_mark.draw_circle(die.position + die.size * p, pip_r, BRASS)
	var bolt := PackedVector2Array()
	for p: Vector2 in [Vector2(0.62, 0.02), Vector2(0.92, 0.02), Vector2(0.74, 0.44),
			Vector2(0.98, 0.44), Vector2(0.50, 0.98), Vector2(0.64, 0.56), Vector2(0.40, 0.56)]:
		bolt.append(p * s)
	_mark.draw_colored_polygon(bolt, AMBER)


func _on_play_pressed() -> void:
	RunCoordinator.new_run()
	get_tree().change_scene_to_file(THROW_SCENE)
