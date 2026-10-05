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

@onready var _gold_label: Label = $GoldLabel
@onready var _status_label: Label = $StatusLabel
@onready var _offer_container: VBoxContainer = $OfferContainer
@onready var _reroll_button: Button = $RerollButton
@onready var _continue_button: Button = $ContinueButton


func _ready() -> void:
	_ledger = RunCoordinator.ledger
	_shop_config = RunCoordinator.shop_config
	_apply_layout()
	_reroll_button.pressed.connect(_on_reroll_pressed)
	_continue_button.pressed.connect(_on_continue_pressed)
	_refresh_offers()
	_update_gold_label()
	_update_button_states()


func _apply_layout() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_set_rect(_gold_label,    0.0, 0.0, 1.0, 0.0,   0.0,    0.0,   0.0,  110.0)
	_set_rect(_status_label,  0.0, 0.0, 1.0, 0.0,   0.0,  120.0,   0.0,  230.0)
	_set_rect(_offer_container, 0.0, 0.0, 1.0, 0.0, 40.0, 250.0, -40.0, 1800.0)
	_set_rect(_reroll_button, 0.0, 1.0, 0.5, 1.0,  40.0, -280.0, -10.0, -140.0)
	_set_rect(_continue_button, 0.5, 1.0, 1.0, 1.0, 10.0, -280.0, -40.0, -140.0)


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
		_offer_container.add_child(_build_offer_card(i, offer))


func _build_offer_card(index: int, offer: ShopOffer) -> HBoxContainer:
	var card := HBoxContainer.new()
	card.custom_minimum_size.y = 160.0

	var name_label := Label.new()
	name_label.text = offer.label
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.add_theme_font_size_override("font_size", 44)
	card.add_child(name_label)

	var cost_label := Label.new()
	cost_label.text = "%dg" % offer.cost if offer.cost > 0 else "FREE"
	cost_label.add_theme_font_size_override("font_size", 40)
	card.add_child(cost_label)

	var buy_btn := Button.new()
	buy_btn.text = "BUY"
	buy_btn.custom_minimum_size.x = 200.0
	buy_btn.add_theme_font_size_override("font_size", 44)
	var captured_index := index
	buy_btn.pressed.connect(func() -> void: _on_buy_pressed(captured_index))
	card.add_child(buy_btn)
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
	_update_gold_label()
	_update_button_states()


func _on_reroll_pressed() -> void:
	if not _ledger.spend(_shop_config.reroll_cost):
		return
	_refresh_offers()
	_update_gold_label()
	_update_button_states()


func _on_continue_pressed() -> void:
	RunCoordinator.on_shop_continued()


func _update_gold_label() -> void:
	_gold_label.text = "Gold: %d" % _ledger.gold


func _update_button_states() -> void:
	_reroll_button.disabled = not _ledger.can_afford(_shop_config.reroll_cost)
	var inv_full := RunCoordinator.inventory.is_full()
	var trinket_inv_full := RunCoordinator.trinket_inventory.is_full()
	var card_children := _offer_container.get_children()
	for i in _offers.size():
		var offer := _offers[i]
		if i >= card_children.size():
			break
		var card := card_children[i] as HBoxContainer
		if card == null:
			continue
		var buy_btn := card.get_child(2) as Button
		if buy_btn == null:
			continue
		var is_charm := i < _offer_charms.size() and _offer_charms[i] != null
		var is_trinket := i < _offer_trinkets.size() and _offer_trinkets[i] != null
		var blocked_by_inv := (is_charm and inv_full) or (is_trinket and trinket_inv_full)
		buy_btn.disabled = offer.sold or blocked_by_inv or not _ledger.can_afford(offer.cost)
		card.modulate = Color(0.45, 0.45, 0.45) if offer.sold else Color.WHITE
