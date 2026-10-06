class_name UiStyle
extends RefCounted
## The Smoke Room UI theme (ui-theme spec). Chrome comes from the rendered UI kit in
## res://assets/ui/ as 9-patch StyleBoxTextures; colours are the art-direction palette.
## Shared by every screen: set `theme = UiStyle.theme()` on a root.

const BRASS := Color("#CC994C")  # palette_ui_line
const AMBER := Color("#FF9E29")  # palette_accent
const CREAM := Color("#F2E6D0")
const MUTED := Color("#8A7A64")
const OUTLINE := Color("#1A0B06")
const UI_DIR := "res://assets/ui/"
## 9-patch margins in px, matching the kit renders (art-direction spec).
const MARGIN_BUTTON := 40
const MARGIN_PANEL := 48
const MARGIN_PLAQUE := 32
const MARGIN_SOCKET := 52
const TIMER_FRAME_MARGINS := Vector2i(36, 26)
const TIMER_FILL_MARGINS := Vector2i(16, 14)

static var _theme: Theme


static func theme() -> Theme:
	if _theme == null:
		_theme = _build()
	return _theme


static func kit(piece: String) -> Texture2D:
	return load(UI_DIR + piece + ".png") as Texture2D


static func box(piece: String, margin: int, content := Vector2(24.0, 16.0),
		modulate := Color.WHITE) -> StyleBoxTexture:
	var b := StyleBoxTexture.new()
	b.texture = kit(piece)
	b.set_texture_margin_all(margin)
	b.content_margin_left = content.x
	b.content_margin_right = content.x
	b.content_margin_top = content.y
	b.content_margin_bottom = content.y
	b.modulate_color = modulate
	return b


## A NinePatchRect for the timer pieces (frame and fill).
static func nine_patch(piece: String, margins: Vector2i) -> NinePatchRect:
	var n := NinePatchRect.new()
	n.texture = kit(piece)
	n.patch_margin_left = margins.x
	n.patch_margin_right = margins.x
	n.patch_margin_top = margins.y
	n.patch_margin_bottom = margins.y
	n.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return n


## A charm medallion at `px` square, mipmapped so the 256² render downsamples cleanly.
static func charm_badge(icon: Texture2D, px: float) -> TextureRect:
	var r := TextureRect.new()
	r.texture = icon
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	r.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	r.custom_minimum_size = Vector2(px, px)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return r


## A row of charm medallions (the run's build); empty slots show a dim socket.
static func charm_row(charms: Array, slots: int, px: float) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 16)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for i in slots:
		if i < charms.size() and (charms[i] as CharmEffect).icon != null:
			row.add_child(charm_badge((charms[i] as CharmEffect).icon, px))
		else:
			var empty := charm_badge(kit("socket"), px)
			empty.modulate = Color(0.55, 0.55, 0.55)
			row.add_child(empty)
	return row


static func _button_styles(t: Theme, type: StringName, kind: String) -> void:
	var content := Vector2(44.0, 22.0)
	t.set_stylebox("normal", type, box("button_%s_normal" % kind, MARGIN_BUTTON, content))
	t.set_stylebox("hover", type, box("button_%s_normal" % kind, MARGIN_BUTTON, content, Color(1.12, 1.12, 1.12)))
	t.set_stylebox("pressed", type, box("button_%s_pressed" % kind, MARGIN_BUTTON, content))
	t.set_stylebox("disabled", type, box("button_%s_disabled" % kind, MARGIN_BUTTON, content))
	t.set_stylebox("focus", type, StyleBoxEmpty.new())
	t.set_color("font_color", type, CREAM)
	t.set_color("font_hover_color", type, Color.WHITE)
	t.set_color("font_pressed_color", type, AMBER)
	t.set_color("font_focus_color", type, CREAM)
	t.set_color("font_disabled_color", type, MUTED)
	t.set_color("font_outline_color", type, OUTLINE)
	t.set_constant("outline_size", type, 6)


static func _build() -> Theme:
	var t := Theme.new()
	t.default_font_size = 44
	_button_styles(t, &"Button", "secondary")
	# THROW / PLAY / CONTINUE: the one oxblood-lacquer call to action.
	t.set_type_variation(&"ThrowButton", &"Button")
	_button_styles(t, &"ThrowButton", "primary")
	t.set_font_size("font_size", &"ThrowButton", 60)
	# Owned-charm slots sit in recessed brass sockets; empty ones are dimmed.
	t.set_type_variation(&"SlotButton", &"Button")
	_button_styles(t, &"SlotButton", "secondary")
	var socket_content := Vector2(18.0, 14.0)
	t.set_stylebox("normal", &"SlotButton", box("socket", MARGIN_SOCKET, socket_content))
	t.set_stylebox("hover", &"SlotButton", box("socket", MARGIN_SOCKET, socket_content, Color(1.15, 1.15, 1.15)))
	t.set_stylebox("pressed", &"SlotButton", box("socket", MARGIN_SOCKET, socket_content, Color(1.3, 1.2, 1.0)))
	t.set_stylebox("disabled", &"SlotButton", box("socket", MARGIN_SOCKET, socket_content, Color(0.55, 0.55, 0.55)))
	t.set_font_size("font_size", &"SlotButton", 28)
	t.set_stylebox("panel", &"PanelContainer", box("panel", MARGIN_PANEL, Vector2(40.0, 30.0)))
	t.set_stylebox("panel", &"Panel", box("panel", MARGIN_PANEL, Vector2(40.0, 30.0)))
	# Inset brass plaque behind readouts (round total, gold).
	t.set_type_variation(&"PlaquePanel", &"Panel")
	t.set_stylebox("panel", &"PlaquePanel", box("plaque", MARGIN_PLAQUE))
	t.set_color("font_color", &"Label", CREAM)
	t.set_color("font_shadow_color", &"Label", Color(0, 0, 0, 0.7))
	t.set_constant("shadow_offset_x", &"Label", 2)
	t.set_constant("shadow_offset_y", &"Label", 3)
	t.set_type_variation(&"HudValue", &"Label")
	t.set_color("font_color", &"HudValue", AMBER)
	t.set_type_variation(&"CardBody", &"Label")
	t.set_color("font_color", &"CardBody", CREAM.darkened(0.12))
	t.set_font_size("font_size", &"CardBody", 32)
	return t
