class_name InspectCard
extends PanelContainer
## Shared inspect card (ui-theme spec, add-inspect-card): icon, name, type tag and the
## full rule text for any charm, die or trinket. Opened by the screens that show
## items; any tap anywhere dismisses it. It never takes input itself, so a die tap
## during a lock window still locks, and it never pauses anything.

const WIDTH := 980.0
const ICON_PX := 150.0

var title_label: Label
var tag_label: Label
var body_label: Label
var cost_label: Label
var _icon: TextureRect
## A soft dark scrim behind the card so it reads as "on top", not as another card.
var _scrim: ColorRect


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(WIDTH, 0.0)
	visible = false
	z_index = 10
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 28)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(row)
	_icon = UiStyle.charm_badge(null, ICON_PX)
	_icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(_icon)
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 6)
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(col)
	title_label = _label(col, 48, UiStyle.CREAM)
	tag_label = _label(col, 30, UiStyle.MUTED)
	body_label = _label(col, 36, UiStyle.CREAM.darkened(0.08))
	body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body_label.custom_minimum_size.x = WIDTH - 80.0 - ICON_PX - 28.0
	cost_label = _label(col, 32, UiStyle.AMBER)
	# Top-level child drawn behind the card: containers skip top-level children, and it
	# lives and dies with the card.
	_scrim = ColorRect.new()
	_scrim.color = Color(0.0, 0.0, 0.0, 0.45)
	_scrim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_scrim.top_level = true
	_scrim.show_behind_parent = true
	add_child(_scrim)


func _label(parent: Control, size: int, color: Color) -> Label:
	var l := Label.new()
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(l)
	return l


## Show the card for an item resource (charm, dice material, carved die, trinket),
## with its bottom edge at `bottom_y` (canvas units), centred horizontally.
func show_item(item: Resource, bottom_y: float, show_cost: bool = false) -> void:
	_icon.texture = item.get("icon")
	_icon.visible = _icon.texture != null
	title_label.text = String(item.get("display_name"))
	tag_label.text = tag_for(item)
	body_label.text = String(item.get("description"))
	var cost: int = int(item.get("cost")) if item.get("cost") != null else 0
	cost_label.text = "%dg" % cost
	cost_label.visible = show_cost and cost > 0
	visible = true
	_scrim.global_position = Vector2.ZERO
	_scrim.size = get_viewport_rect().size
	reset_size()
	var vw := get_viewport_rect().size.x
	position = Vector2((vw - size.x) * 0.5, bottom_y - size.y)
	pivot_offset = size * Vector2(0.5, 1.0)
	scale = Vector2(0.92, 0.92)
	modulate.a = 0.0
	var t := create_tween()
	t.tween_property(self, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.parallel().tween_property(self, "modulate:a", 1.0, 0.1)


static func tag_for(item: Resource) -> String:
	if item is CharmEffect:
		return "CHARM · always on"
	if item is CarvedDieOffer:
		return "CARVED DIE · joins your bag"
	if item is DiceMaterial:
		return "%s DIE · joins your bag" % String(item.get("display_name")).to_upper()
	if item is Trinket:
		return "TRINKET · one use, during a lock window"
	return ""


func _input(event: InputEvent) -> void:
	# Any tap dismisses; the event is NOT consumed, so it still reaches the die or
	# button underneath (a tap on another item simply reopens the card for it).
	if visible and event is InputEventMouseButton and (event as InputEventMouseButton).pressed:
		visible = false
