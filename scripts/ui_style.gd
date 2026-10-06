class_name UiStyle
extends RefCounted
## The Smoke Room UI theme (ui-theme spec), built once from the art-direction
## palette and shared by every screen: set `theme = UiStyle.theme()` on a root.

const PANEL := Color(0.055, 0.031, 0.027, 0.9)  # #0E0807 at 90%
const BRASS := Color("#CC994C")  # palette_ui_line
const AMBER := Color("#FF9E29")  # palette_accent
const CREAM := Color("#F2E6D0")
const MUTED := Color("#8A7A64")
const OXBLOOD := Color("#5C0D0F")  # palette_felt
const BUTTON := Color("#1A0F0C")

static var _theme: Theme


static func theme() -> Theme:
	if _theme == null:
		_theme = _build()
	return _theme


static func _box(bg: Color, border: Color, width: int, radius: int, margin: float) -> StyleBoxFlat:
	var b := StyleBoxFlat.new()
	b.bg_color = bg
	b.border_color = border
	b.set_border_width_all(width)
	b.set_corner_radius_all(radius)
	b.set_content_margin_all(margin)
	b.anti_aliasing = true
	return b


static func _button_styles(t: Theme, type: StringName, base: Color, border_w: int) -> void:
	t.set_stylebox("normal", type, _box(base, BRASS, border_w, 12, 18.0))
	t.set_stylebox("hover", type, _box(base.lightened(0.08), BRASS.lightened(0.15), border_w, 12, 18.0))
	t.set_stylebox("pressed", type, _box(base.lightened(0.15), AMBER, border_w, 12, 18.0))
	t.set_stylebox("disabled", type, _box(base.darkened(0.45), MUTED.darkened(0.3), border_w, 12, 18.0))
	t.set_stylebox("focus", type, StyleBoxEmpty.new())
	t.set_color("font_color", type, CREAM)
	t.set_color("font_hover_color", type, Color.WHITE)
	t.set_color("font_pressed_color", type, AMBER)
	t.set_color("font_focus_color", type, CREAM)
	t.set_color("font_disabled_color", type, MUTED)


static func _build() -> Theme:
	var t := Theme.new()
	t.default_font_size = 44
	_button_styles(t, &"Button", BUTTON, 2)
	# THROW / PLAY: the one oxblood call to action.
	t.set_type_variation(&"ThrowButton", &"Button")
	_button_styles(t, &"ThrowButton", OXBLOOD, 3)
	t.set_font_size("font_size", &"ThrowButton", 60)
	# Owned-charm slots: smaller text so names wrap inside a 184 px slot.
	t.set_type_variation(&"SlotButton", &"Button")
	_button_styles(t, &"SlotButton", BUTTON, 2)
	t.set_font_size("font_size", &"SlotButton", 28)
	t.set_stylebox("panel", &"PanelContainer", _box(PANEL, BRASS, 2, 14, 22.0))
	t.set_stylebox("panel", &"Panel", _box(PANEL, BRASS, 2, 14, 22.0))
	t.set_color("font_color", &"Label", CREAM)
	t.set_type_variation(&"HudValue", &"Label")
	t.set_color("font_color", &"HudValue", AMBER)
	t.set_type_variation(&"CardBody", &"Label")
	t.set_color("font_color", &"CardBody", CREAM.darkened(0.15))
	t.set_font_size("font_size", &"CardBody", 32)
	return t
