extends Control
## Shop screen shown between antes. Reads run state from RunCoordinator;
## all gold mutations go through GoldLedger. Charm and dice offers come from
## the item pool, shuffled via the shop RNG stream.

const _CHARM_PATHS: Array[String] = [
	"res://resources/charms/quick_draw.tres",
	"res://resources/charms/loaded.tres",
	"res://resources/charms/snake_charmer.tres",
	"res://resources/charms/hair_trigger.tres",
	"res://resources/charms/adrenaline.tres",
	"res://resources/charms/patient_zero.tres",
	"res://resources/charms/ice_cold.tres",
	"res://resources/charms/big_bucks.tres",
	"res://resources/charms/precision.tres",
	"res://resources/charms/collector.tres",
	"res://resources/charms/high_roller.tres",
	"res://resources/charms/straight_edge.tres",
]

const _MATERIAL_PATHS: Array[String] = [
	"res://resources/dice_materials/iron.tres",
	"res://resources/dice_materials/glass.tres",
]

const _TRINKET_PATHS: Array[String] = [
	"res://resources/trinkets/re_tumble.tres",
	"res://resources/trinkets/freeze_timer.tres",
]

const _CARVED_DIE_PATHS: Array[String] = [
	"res://resources/carved_dice/wild_6_bone.tres",
	"res://resources/carved_dice/gem_5_bone.tres",
	"res://resources/carved_dice/spark_4_bone.tres",
]

var _ledger: GoldLedger
var _shop_config: ShopConfig
var _offers: Array[ShopOffer] = []
var _offer_charms: Array[CharmEffect] = []
var _offer_materials: Array[DiceMaterial] = []
var _offer_trinkets: Array[Trinket] = []
var _offer_carved: Array[CarvedDieOffer] = []
var _buy_buttons: Array[Button] = []
var _owned_label: Label
var _owned_icons: HBoxContainer
var _build_caption: Label
var _dice_caption: Label
var _dice_label: Label
var _inspect: InspectCard
var _next_label: Label
## YOUR DICE as icons with ×count badges (add-shop-clarity).
var _dice_row: HBoxContainer
const BLOCKED_RED := Color(0.85, 0.42, 0.36)
## Inspect card bottom edges (canvas units): in the gap under your build / above the offers.
const INSPECT_BUILD_Y := 990.0
const INSPECT_OFFER_Y := 1090.0
var _gold_panel: Panel

@onready var _gold_label: Label = $GoldLabel
@onready var _status_label: Label = $StatusLabel
@onready var _offer_container: VBoxContainer = $OfferContainer
@onready var _reroll_button: Button = $RerollButton
@onready var _continue_button: Button = $ContinueButton


func _ready() -> void:
	theme = UiStyle.theme()
	_gold_panel = Panel.new()
	_gold_panel.theme_type_variation = &"PlaquePanel"
	_gold_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_gold_panel)
	move_child(_gold_panel, 0)
	_gold_label.theme_type_variation = &"HudValue"
	_gold_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_gold_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_owned_label = Label.new()
	_owned_label.theme_type_variation = &"CardBody"
	_owned_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_owned_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(_owned_label)
	_build_caption = _caption("YOUR BUILD")
	_dice_caption = _caption("YOUR DICE")
	_dice_label = Label.new()
	_dice_label.theme_type_variation = &"CardBody"
	_dice_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_dice_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(_dice_label)
	_offer_container.add_theme_constant_override("separation", 24)
	_continue_button.theme_type_variation = &"ThrowButton"
	SmokeOverlay.add_backdrop(self)
	SmokeOverlay.add_to(self)
	_ledger = RunCoordinator.ledger
	_shop_config = RunCoordinator.shop_config
	_inspect = InspectCard.new()
	add_child(_inspect)
	var coach := CoachMark.new()
	add_child(coach)
	if Settings.take_tip("first_shop"):
		coach.show_tip.call_deferred("Charms change how you score. Tap any icon to read it.",
			Rect2(40.0, 1100.0, 1000.0, 860.0))
	# What's next (add-ante-intro-card): shop with the coming target and rule in mind.
	_next_label = Label.new()
	_next_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_next_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_next_label.add_theme_font_size_override("font_size", 32)
	_next_label.add_theme_color_override("font_color", UiStyle.AMBER)
	_next_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_next_label)
	_next_label.text = next_ante_text()
	_apply_layout()
	_reroll_button.pressed.connect(_on_reroll_pressed)
	_continue_button.pressed.connect(_on_continue_pressed)
	_refresh_offers()
	_update_gold_label()
	_update_owned_label()
	_update_button_states()


func _apply_layout() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	# ui-theme spec: gold readout on top, owned build, then offer cards in the lower
	# half so every BUY sits in the bottom 55%; RE-ROLL / CONTINUE in the thumb zone.
	if _gold_panel != null:
		_set_rect(_gold_panel, 0.0, 0.0, 1.0, 0.0, 24.0, 20.0, -24.0, 200.0)
	_set_rect(_gold_label, 0.0, 0.0, 1.0, 0.0, 40.0, 40.0, -40.0, 180.0)
	# Two groups: what you have (build, dice) up top; what you can buy below, with
	# its heading sitting right on the cards.
	if _owned_label != null:
		_set_rect(_build_caption, 0.0, 0.0, 1.0, 0.0, 60.0, 232.0, -60.0, 272.0)
		_set_rect(_owned_label, 0.0, 0.0, 1.0, 0.0, 60.0, 450.0, -60.0, 540.0)
		_set_rect(_dice_caption, 0.0, 0.0, 1.0, 0.0, 60.0, 600.0, -60.0, 640.0)
		_set_rect(_dice_label, 0.0, 0.0, 1.0, 0.0, 60.0, 752.0, -60.0, 810.0)
	if _next_label != null:
		_set_rect(_next_label, 0.0, 0.0, 1.0, 0.0, 60.0, 830.0, -60.0, 960.0)
	_set_rect(_status_label, 0.0, 0.0, 1.0, 0.0, 40.0, 990.0, -40.0, 1090.0)
	_set_rect(_offer_container, 0.0, 0.0, 1.0, 0.0, 40.0, 1100.0, -40.0, 1960.0)
	_set_rect(_reroll_button, 0.0, 1.0, 0.5, 1.0, 40.0, -300.0, -12.0, -120.0)
	_set_rect(_continue_button, 0.5, 1.0, 1.0, 1.0, 12.0, -300.0, -40.0, -120.0)


func _set_rect(c: Control, al: float, at: float, ar: float, ab: float,
		ol: float, ot: float, orr: float, ob: float) -> void:
	c.anchor_left = al
	c.anchor_top = at
	c.anchor_right = ar
	c.anchor_bottom = ab
	c.offset_left = ol
	c.offset_top = ot
	c.offset_right = orr
	c.offset_bottom = ob


func _build_item_pool() -> Array:
	var owned: Dictionary = {}
	for charm in RunCoordinator.inventory.iter_charms():
		owned[charm.get_script()] = true
	var pool: Array = []
	for path in _CHARM_PATHS:
		var charm := load(path) as CharmEffect
		if not owned.has(charm.get_script()):
			pool.append({"kind": "charm", "res": charm})
	for path in _MATERIAL_PATHS:
		var mat := load(path) as DiceMaterial
		if mat != null:
			pool.append({"kind": "die", "res": mat})
	for path in _TRINKET_PATHS:
		var trinket := load(path) as Trinket
		if trinket != null:
			pool.append({"kind": "trinket", "res": trinket})
	for path in _CARVED_DIE_PATHS:
		var carved := load(path) as CarvedDieOffer
		if carved != null:
			pool.append({"kind": "carved_die", "res": carved})
	RngService.shuffle_shop(pool)
	return pool


func _refresh_offers() -> void:
	for child in _offer_container.get_children():
		child.queue_free()
	_offers.clear()
	_buy_buttons.clear()
	_offer_charms.clear()
	_offer_materials.clear()
	_offer_trinkets.clear()
	_offer_carved.clear()

	var pool := _build_item_pool()
	var count := mini(3, pool.size())
	for i in count:
		var item: Dictionary = pool[i]
		var res_name: String = item.res.display_name
		var res_cost: int = item.res.cost
		var offer := ShopOffer.make(ShopOffer.Type.CHARM_STUB, res_name, res_cost)
		_offers.append(offer)
		if item.kind == "charm":
			_offer_charms.append(item.res as CharmEffect)
			_offer_materials.append(null)
			_offer_trinkets.append(null)
			_offer_carved.append(null)
		elif item.kind == "die":
			_offer_charms.append(null)
			_offer_materials.append(item.res as DiceMaterial)
			_offer_trinkets.append(null)
			_offer_carved.append(null)
		elif item.kind == "trinket":
			_offer_charms.append(null)
			_offer_materials.append(null)
			_offer_trinkets.append(item.res as Trinket)
			_offer_carved.append(null)
		else:
			_offer_charms.append(null)
			_offer_materials.append(null)
			_offer_trinkets.append(null)
			_offer_carved.append(item.res as CarvedDieOffer)
		_offer_container.add_child(_build_offer_card(i, offer, item.res.description, item.res.get("icon"), item.res))


## Offer card (ui-theme spec): name · cost, the full effect description, and BUY.
func _build_offer_card(index: int, offer: ShopOffer, description: String,
		icon: Texture2D = null, res: Resource = null) -> PanelContainer:
	var card := PanelContainer.new()
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 24)
	card.add_child(row)
	if icon != null:  # charms carry a medallion (add-charm-icons)
		var badge := UiStyle.charm_badge(icon, 132.0)
		badge.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		if res != null:
			UiStyle.pickable(badge, func() -> void: _inspect.show_item(res, INSPECT_OFFER_Y, true))
		row.add_child(badge)
	var text := VBoxContainer.new()
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(text)

	var name_label := Label.new()
	name_label.text = "%s  ·  %s" % [offer.label, "%dg" % offer.cost if offer.cost > 0 else "FREE"]
	text.add_child(name_label)
	card.set_meta(&"name_label", name_label)
	if icon != null:
		card.set_meta(&"badge", row.get_child(0))
	var body := Label.new()
	body.theme_type_variation = &"CardBody"
	body.text = description
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.add_child(body)

	var buy_btn := Button.new()
	buy_btn.text = "BUY"
	buy_btn.custom_minimum_size = Vector2(220.0, 130.0)
	buy_btn.clip_text = true  # "NEED 3g" / "SLOTS FULL" never widen the button
	buy_btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var captured_index := index
	buy_btn.pressed.connect(func() -> void: _on_buy_pressed(captured_index))
	# A disabled BUY still answers a tap: it says why (add-shop-clarity).
	buy_btn.gui_input.connect(func(e: InputEvent) -> void:
		var mb := e as InputEventMouseButton
		if mb != null and not mb.pressed and buy_btn.disabled:
			_on_blocked_tap(captured_index))
	row.add_child(buy_btn)
	_buy_buttons.append(buy_btn)
	return card


func _on_buy_pressed(index: int) -> void:
	var offer := _offers[index]
	if offer.sold:
		return
	var charm: CharmEffect = _offer_charms[index] if index < _offer_charms.size() else null
	var mat: DiceMaterial = _offer_materials[index] if index < _offer_materials.size() else null
	var trinket: Trinket = _offer_trinkets[index] if index < _offer_trinkets.size() else null
	var carved: CarvedDieOffer = _offer_carved[index] if index < _offer_carved.size() else null
	if charm != null and RunCoordinator.inventory.is_full():
		return
	if trinket != null and RunCoordinator.trinket_inventory.is_full():
		return
	if not _ledger.spend(offer.cost):
		return
	if charm != null:
		RunCoordinator.inventory.add_charm(charm)
	elif mat != null:
		RunCoordinator.bag.add(mat.material_id)
	elif trinket != null:
		RunCoordinator.trinket_inventory.add_trinket(trinket)
	elif carved != null:
		RunCoordinator.bag.add_carved(carved.material_id, carved.carved_face, carved.carve_type)
	offer.sold = true
	_status_label.text = "Bought: %s" % offer.label
	var card := _buy_buttons[index].get_parent().get_parent() as Control
	var from: Rect2 = (card.get_meta(&"badge") as Control).get_global_rect() if card.has_meta(&"badge") else Rect2()
	var gold_before := _ledger.gold + offer.cost
	_update_owned_label()
	_update_button_states()
	_tick_gold(gold_before, _ledger.gold)
	if from.size != Vector2.ZERO:
		_fly_in(card.get_meta(&"badge").texture, from, _landing_for(charm, mat, carved))


func _on_reroll_pressed() -> void:
	if not _ledger.spend(_shop_config.reroll_cost):
		return
	_refresh_offers()
	_update_gold_label()
	_update_button_states()


func _on_continue_pressed() -> void:
	RunCoordinator.on_shop_continued()


## "NEXT: ANTE 3 · BOSS · TARGET 700 · ½ WINDOWS" for the ante the shop leads into.
func next_ante_text() -> String:
	var arc := RunCoordinator.arc
	if arc == null:
		return ""
	var b := AnteBrief.for_ante(arc.current_ante, preload("res://resources/ante_arc.tres"),
		_shop_config if _shop_config != null else RunCoordinator.shop_config,
		preload("res://resources/throw_config.tres"))
	var text := "NEXT: %s · TARGET %d" % [b.title, b.target]
	return text + (" · " + b.short_rule if b.is_boss else "")


func _caption(text: String) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", 30)
	l.add_theme_color_override("font_color", UiStyle.MUTED)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(l)
	return l


func _update_gold_label() -> void:
	_gold_label.text = "Gold: %d" % _ledger.gold


## Why an offer can't be bought right now ("" = it can): the BUY label (shop-scene spec).
func buy_block_reason(i: int) -> String:
	var offer := _offers[i]
	if offer.sold:
		return "SOLD"
	var is_charm := i < _offer_charms.size() and _offer_charms[i] != null
	var is_trinket := i < _offer_trinkets.size() and _offer_trinkets[i] != null
	if (is_charm and RunCoordinator.inventory.is_full()) or (is_trinket and RunCoordinator.trinket_inventory.is_full()):
		return "SLOTS FULL"
	if not _ledger.can_afford(offer.cost):
		return "NEED %dg" % (offer.cost - _ledger.gold)
	return ""


func _on_blocked_tap(i: int) -> void:
	var reason := buy_block_reason(i)
	if reason == "" or reason == "SOLD":
		return
	var btn := _buy_buttons[i]
	var home := btn.position.x
	var t := create_tween()
	for dx: float in [14.0, -11.0, 7.0, -4.0, 0.0]:
		t.tween_property(btn, "position:x", home + dx, 0.04)
	if reason == "SLOTS FULL":
		_status_label.text = "Slots full: %d / %d" % [CharmInventory.MAX_SLOTS, CharmInventory.MAX_SLOTS] \
			if i < _offer_charms.size() and _offer_charms[i] != null else "Trinket slots full"
	else:
		_status_label.text = "Need %d more gold" % (_offers[i].cost - _ledger.gold)
		_punch(_gold_label, 1.2)


func _punch(c: Control, amount: float) -> void:
	c.pivot_offset = c.size / 2.0
	var t := create_tween()
	t.tween_property(c, "scale", Vector2.ONE * amount, 0.08)
	t.tween_property(c, "scale", Vector2.ONE, 0.18)


func _tick_gold(from: int, to: int) -> void:
	var t := create_tween()
	t.tween_method(func(v: float) -> void: _gold_label.text = "Gold: %d" % roundi(v), float(from), float(to), 0.35)
	_punch(_gold_label, 1.12)


## Where a purchase lands: its charm socket, its die in YOUR DICE, else the gold plaque.
func _landing_for(charm: CharmEffect, mat: DiceMaterial, carved: CarvedDieOffer) -> Control:
	if charm != null and _owned_icons != null:
		var idx := RunCoordinator.inventory.iter_charms().find(charm)
		if idx >= 0 and idx < _owned_icons.get_child_count():
			return _owned_icons.get_child(idx)
	if (mat != null or carved != null) and _dice_row != null:
		for c in _dice_row.get_children():
			var g: Dictionary = c.get_meta(&"group", {})
			if carved != null and g.get("carve_type") == carved.carve_type and g.get("carved_face") == carved.carved_face:
				return c
			if mat != null and g.get("carve_type") == &"" and g.get("material_id") == mat.material_id:
				return c
	return _gold_label


## The bought icon flies from its card to where it lands, then pops with sparks.
func _fly_in(tex: Texture2D, from: Rect2, target: Control) -> void:
	var fly := UiStyle.charm_badge(tex, from.size.x)
	fly.top_level = true
	fly.z_index = 20
	add_child(fly)
	fly.global_position = from.position
	fly.size = from.size
	var to := target.get_global_rect().get_center() - from.size / 2.0
	var t := create_tween()
	t.tween_property(fly, "global_position", to, 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	t.parallel().tween_property(fly, "scale", Vector2.ONE * 0.8, 0.45)
	t.tween_callback(func() -> void:
		fly.queue_free()
		_punch(target, 1.25)
		ScoreHud.spawn_burst(self, target.get_global_rect().get_center(), 16))


## YOUR DICE as a row of die icons with ×count badges; tap one to inspect it.
func _rebuild_dice_row() -> void:
	if _dice_row != null:
		_dice_row.queue_free()
	_dice_row = HBoxContainer.new()
	_dice_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_dice_row.add_theme_constant_override("separation", 18)
	_dice_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_dice_row)
	_set_rect(_dice_row, 0.0, 0.0, 1.0, 0.0, 40.0, 646.0, -40.0, 750.0)
	for g in RunCoordinator.bag.groups():
		var res := _resource_for_group(g)
		var cell := Control.new()
		cell.custom_minimum_size = Vector2(104.0, 104.0)
		cell.set_meta(&"group", g)
		var icon := UiStyle.charm_badge(res.get("icon") if res != null else null, 104.0)
		cell.add_child(icon)
		icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		var count := Label.new()
		count.text = "×%d" % g.count
		count.add_theme_font_size_override("font_size", 30)
		count.add_theme_color_override("font_color", UiStyle.CREAM)
		count.add_theme_color_override("font_outline_color", UiStyle.OUTLINE)
		count.add_theme_constant_override("outline_size", 8)
		count.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cell.add_child(count)
		count.position = Vector2(62.0, 62.0)
		if res != null:
			UiStyle.pickable(cell, func() -> void: _inspect.show_item(res, INSPECT_BUILD_Y))
		_dice_row.add_child(cell)


func _resource_for_group(g: Dictionary) -> Resource:
	if g.carve_type != &"":
		for path in _CARVED_DIE_PATHS:
			var c := load(path) as CarvedDieOffer
			if c != null and c.carve_type == g.carve_type and c.carved_face == g.carved_face and c.material_id == g.material_id:
				return c
		return null
	return DiceMaterial.by_id(g.material_id)


## "Charms 2 / 5: Quick Draw, Loaded" (ui-theme spec), so slot limits are visible.
func _update_owned_label() -> void:
	var names: Array[String] = []
	for charm in RunCoordinator.inventory.iter_charms():
		names.append(charm.display_name)
	var line := "Charms %d / %d" % [names.size(), CharmInventory.MAX_SLOTS]
	_owned_label.text = line + (": " + ", ".join(names) if not names.is_empty() else "")
	# The build as medallions under the line (add-charm-icons).
	if _owned_icons != null:
		_owned_icons.queue_free()
	_owned_icons = UiStyle.charm_row(RunCoordinator.inventory.iter_charms(), CharmInventory.MAX_SLOTS, 150.0,
		func(c: CharmEffect) -> void: _inspect.show_item(c, INSPECT_BUILD_Y))
	add_child(_owned_icons)
	_set_rect(_owned_icons, 0.0, 0.0, 1.0, 0.0, 40.0, 282.0, -40.0, 442.0)
	_dice_label.text = RunCoordinator.bag.summary()
	_rebuild_dice_row()


func _update_button_states() -> void:
	_reroll_button.disabled = not _ledger.can_afford(_shop_config.reroll_cost)
	var inv_full := RunCoordinator.inventory.is_full()
	var trinket_inv_full := RunCoordinator.trinket_inventory.is_full()
	for i in mini(_offers.size(), _buy_buttons.size()):
		var offer := _offers[i]
		var buy_btn := _buy_buttons[i]
		var card := buy_btn.get_parent().get_parent() as Control
		var is_charm := i < _offer_charms.size() and _offer_charms[i] != null
		var is_trinket := i < _offer_trinkets.size() and _offer_trinkets[i] != null
		var blocked_by_inv := (is_charm and inv_full) or (is_trinket and trinket_inv_full)
		buy_btn.disabled = offer.sold or blocked_by_inv or not _ledger.can_afford(offer.cost)
		card.modulate = Color(0.45, 0.45, 0.45) if offer.sold else Color.WHITE
		var reason := buy_block_reason(i)
		buy_btn.text = "BUY" if reason == "" else reason
		buy_btn.add_theme_font_size_override("font_size", 44 if reason == "" else 30)
		if card.has_meta(&"name_label"):
			var nl := card.get_meta(&"name_label") as Label
			if reason.begins_with("NEED"):
				nl.add_theme_color_override("font_color", BLOCKED_RED)
			else:
				nl.remove_theme_color_override("font_color")
