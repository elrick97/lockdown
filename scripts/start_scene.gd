extends Control
## Start screen (run-flow spec): Blender-rendered hero mark (no name or logo until PRD Q4), a
## four-line how-to, and PLAY in the thumb zone. Layout is set in code: hand-authored
## scene anchors don't survive the Android export (see project notes).

const THROW_SCENE := "res://scenes/throw/throw_scene.tscn"
const HERO := preload("res://assets/ui/start_hero.png")
## Idle float of the hero: amplitude (px) and period (s).
const HERO_BOB_PX := 14.0
const HERO_BOB_S := 3.2
const HOW_TO := [
	"Throw, then tap dice to lock them.",
	"Beat the timer: unlocked dice re-roll.",
	"Only locked dice score. Make combos.",
	"Lock fast: speed heats up your score.",
]

var _mark: TextureRect
var _how_to: Label
var _play_button: Button
var _how_to_card: Panel


func _ready() -> void:
	theme = UiStyle.theme()
	SmokeOverlay.add_backdrop(self)
	SmokeOverlay.add_to(self)

	_mark = TextureRect.new()
	_mark.texture = HERO
	_mark.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_mark.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_mark)

	_how_to_card = Panel.new()
	_how_to_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_how_to_card)
	_how_to = Label.new()
	_how_to.text = "\n".join(HOW_TO)
	_how_to.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_how_to.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_how_to.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
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
	_start_idle()


func _apply_layout() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_place(_mark, 0.5, 0.0, 0.5, 0.0, -540.0, 60.0, 540.0, 900.0)
	_place(_how_to_card, 0.0, 0.0, 1.0, 0.0, 50.0, 920.0, -50.0, 1420.0)
	_place(_how_to, 0.0, 0.0, 1.0, 0.0, 100.0, 950.0, -100.0, 1390.0)
	_place(_play_button, 0.5, 1.0, 0.5, 1.0, -280.0, -420.0, 280.0, -200.0)


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


## The hero floats gently (the dice "hang" mid-throw) so the screen never sits dead.
func _start_idle() -> void:
	var t := create_tween().set_loops()
	t.tween_property(_mark, "position:y", _mark.position.y - HERO_BOB_PX, HERO_BOB_S * 0.5) 		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	t.tween_property(_mark, "position:y", _mark.position.y, HERO_BOB_S * 0.5) 		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	# PLAY breathes, so the one thing to do next is obvious.
	_play_button.pivot_offset = _play_button.size / 2.0
	var p := create_tween().set_loops()
	p.tween_property(_play_button, "scale", Vector2.ONE * 1.045, 0.9).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	p.tween_property(_play_button, "scale", Vector2.ONE, 0.9).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _on_play_pressed() -> void:
	RunCoordinator.new_run()
	get_tree().change_scene_to_file(THROW_SCENE)
