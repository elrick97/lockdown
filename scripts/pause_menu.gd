class_name PauseMenu
extends Control
## Pause menu (throw-loop / ui-theme spec, add-pause-settings): Resume, How to play,
## Combos, Settings and Abandon run, as pages on one leather card. Runs while the
## tree is paused. In settings-only mode (start screen) it opens straight on Settings
## and closes from there.

signal resume_requested
signal abandon_confirmed
signal closed

const HOW_TO := [
	"Throw, then tap dice to lock them.",
	"Beat the timer: unlocked dice re-roll.",
	"Locks are final: a locked die stays.",
	"Only locked dice score. Make combos.",
	"Lock fast: speed heats up your score.",
]
## (name, how it matches) in the combo-scoring table's order; values from ScoringConfig.
const COMBOS := [
	["Pair", "2 of a kind", ScoringConfig.ComboType.PAIR],
	["Two Pair", "two different pairs", ScoringConfig.ComboType.TWO_PAIR],
	["Triple", "3 of a kind", ScoringConfig.ComboType.TRIPLE],
	["Small Straight", "4 in a row", ScoringConfig.ComboType.SMALL_STRAIGHT],
	["Full House", "a triple + a pair", ScoringConfig.ComboType.FULL_HOUSE],
	["Quad", "4 of a kind", ScoringConfig.ComboType.QUAD],
	["Large Straight", "1-2-3-4-5-6", ScoringConfig.ComboType.LARGE_STRAIGHT],
	["Quint", "5+ of a kind", ScoringConfig.ComboType.QUINT],
]

var settings_only := false
var page := &"main"
var title_label: Label
var _content: VBoxContainer
var _card: Panel
## The card hugs its content and sits low, so every option is in thumb reach.
const CARD_BOTTOM := 2280.0
const CARD_PAD := 70.0
var _scoring: ScoringConfig = preload("res://resources/scoring_config.tres")


func _init() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	visible = false
	var dim := ColorRect.new()
	dim.color = Color(0.0, 0.0, 0.0, 0.55)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	_card = Panel.new()
	_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_card.anchor_right = 1.0
	_card.offset_left = 60.0
	_card.offset_right = -60.0
	_card.offset_bottom = CARD_BOTTOM
	add_child(_card)
	title_label = Label.new()
	ScoreHud.style_stamp(title_label, 96)
	title_label.anchor_right = 1.0
	title_label.offset_left = 40.0
	title_label.offset_right = -40.0
	title_label.offset_top = 220.0
	title_label.offset_bottom = 430.0
	add_child(title_label)
	_content = VBoxContainer.new()
	_content.add_theme_constant_override("separation", 22)
	_content.anchor_right = 1.0
	_content.offset_left = 130.0
	_content.offset_right = -130.0
	_content.offset_top = 470.0
	_content.offset_bottom = 1900.0
	add_child(_content)


func open_main() -> void:
	settings_only = false
	visible = true
	_show(&"main")


func open_settings_only() -> void:
	settings_only = true
	visible = true
	_show(&"settings")


func close() -> void:
	visible = false
	closed.emit()


func _show(p: StringName) -> void:
	page = p
	for c in _content.get_children():
		c.queue_free()
	match p:
		&"main":
			title_label.text = "PAUSED"
			_button("RESUME", _on_resume, true)
			_button("HOW TO PLAY", _show.bind(&"how"))
			_button("COMBOS", _show.bind(&"combos"))
			_button("SETTINGS", _show.bind(&"settings"))
			_button("ABANDON RUN", _show.bind(&"confirm"))
		&"how":
			title_label.text = "HOW TO PLAY"
			_text("\n".join(HOW_TO), 42)
			_back()
		&"combos":
			title_label.text = "COMBOS"
			for row in COMBOS:
				_text("%s — %s · %d × %d" % [row[0], row[1], _scoring.get_chips(row[2]),
					_scoring.get_mult(row[2])], 34)
			_text("Pips are a die's face points. CHIPS = pips + combo and charm chips.\nScore = Chips × Mult × Heat.", 30, UiStyle.MUTED)
			_back()
		&"settings":
			title_label.text = "SETTINGS"
			_setting(Settings.shake_label, Settings.cycle_shake)
			_setting(Settings.speed_label, Settings.cycle_speed)
			_setting(Settings.motion_label, Settings.toggle_reduced_motion)
			_setting(Settings.haptics_label, Settings.toggle_haptics)
			if settings_only:
				_button("DONE", close, true)
			else:
				_back()
		&"confirm":
			title_label.text = "ABANDON RUN?"
			_text("The run ends now and counts as a loss.", 40)
			_button("YES, ABANDON", _on_abandon)
			_button("NO, GO BACK", _show.bind(&"main"), true)
	_fit.call_deferred()


## Size the card to the page and pin it to the bottom; the title stamps on its top edge.
func _fit() -> void:
	var h := _content.get_combined_minimum_size().y
	var top := CARD_BOTTOM - CARD_PAD * 2.0 - h
	_card.offset_top = top
	_content.offset_top = top + CARD_PAD
	_content.offset_bottom = CARD_BOTTOM - CARD_PAD
	title_label.offset_top = top - 120.0
	title_label.offset_bottom = top + 80.0
	ScoreHud.slam(title_label, 1.6)


func _on_resume() -> void:
	close()
	resume_requested.emit()


func _on_abandon() -> void:
	close()
	abandon_confirmed.emit()


func _button(text: String, action: Callable, primary := false) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size.y = 140.0
	if primary:
		b.theme_type_variation = &"ThrowButton"
		b.add_theme_font_size_override("font_size", 48)
	b.pressed.connect(action)
	_content.add_child(b)
	return b


func _setting(label: Callable, action: Callable) -> void:
	var b := _button(label.call(), func() -> void: pass)
	b.pressed.connect(func() -> void:
		action.call()
		b.text = label.call())


func _text(text: String, size: int, color := UiStyle.CREAM) -> void:
	var l := Label.new()
	l.text = text
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_constant_override("line_spacing", 10)
	_content.add_child(l)


func _back() -> void:
	_button("BACK", _show.bind(&"main"), true)
