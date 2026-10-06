extends GutTest
## add-shop-clarity: BUY says why it can't buy, blocked taps explain themselves,
## purchases fly into the build, and YOUR DICE is a row of die icons.

const SHOP_SCENE := preload("res://scenes/shop/shop_scene.tscn")


func after_each() -> void:
	RunCoordinator.new_run()


func _shop(gold: int, charms: Array = []) -> Control:
	RunCoordinator.new_run(3)
	RunCoordinator.ledger.gold = gold
	for id in charms:
		RunCoordinator.inventory.add_charm(load("res://resources/charms/%s.tres" % id))
	var shop: Control = SHOP_SCENE.instantiate()
	add_child_autofree(shop)
	return shop


func _release() -> InputEventMouseButton:
	var ev := InputEventMouseButton.new()
	ev.button_index = MOUSE_BUTTON_LEFT
	ev.pressed = false
	return ev


func test_buy_labels_say_why() -> void:
	var shop := _shop(0)
	for i in shop._buy_buttons.size():
		var cost: int = shop._offers[i].cost
		assert_eq(shop._buy_buttons[i].text, "NEED %dg" % cost, "offer %d" % i)
		var nl: Label = shop._buy_buttons[i].get_parent().get_parent().get_meta(&"name_label")
		assert_true(nl.has_theme_color_override("font_color"), "price dimmed when unaffordable")


func test_full_charm_slots_say_so() -> void:
	var shop := _shop(40, ["hair_trigger", "loaded", "collector", "precision", "big_bucks"])
	shop._offer_charms[0] = load("res://resources/charms/quick_draw.tres")  # force a charm offer
	shop._update_button_states()
	assert_eq(shop._buy_buttons[0].text, "SLOTS FULL")
	assert_true(shop._buy_buttons[0].disabled)


func test_blocked_tap_explains_and_wiggles() -> void:
	var shop := _shop(0)
	shop._buy_buttons[0].gui_input.emit(_release())
	assert_true(shop._status_label.text.begins_with("Need "), shop._status_label.text)


func test_buying_flies_in_ticks_gold_and_marks_sold() -> void:
	var shop := _shop(40)
	var cost: int = shop._offers[0].cost
	shop._buy_buttons[0].pressed.emit()
	assert_eq(shop._buy_buttons[0].text, "SOLD")
	var flying := shop.get_children().filter(func(c: Node) -> bool: return c is TextureRect and (c as TextureRect).top_level)
	assert_eq(flying.size(), 1, "the icon is flying to its place")
	await wait_seconds(0.7)
	assert_eq(shop._gold_label.text, "Gold: %d" % (40 - cost), "gold ticked down")
	assert_eq(shop.get_children().filter(func(c: Node) -> bool: return c is TextureRect and (c as TextureRect).top_level and not c.is_queued_for_deletion()).size(), 0, "and landed")


func test_your_dice_is_an_icon_row_with_counts() -> void:
	RunCoordinator.new_run(3)
	RunCoordinator.bag.add(&"glass", 2)
	RunCoordinator.bag.add_carved(&"standard", 6, &"wild")
	var shop: Control = SHOP_SCENE.instantiate()
	add_child_autofree(shop)
	var cells: Array[Node] = shop._dice_row.get_children()
	assert_eq(cells.size(), 3, "Bone, Glass, Wild 6")
	var cfg: ThrowConfig = load("res://resources/throw_config.tres")
	assert_eq((cells[0].get_child(1) as Label).text, "×%d" % cfg.starting_bag_size)
	assert_eq((cells[1].get_child(1) as Label).text, "×2")
	assert_eq((cells[0].get_child(0) as TextureRect).texture.resource_path, "res://assets/shop/bone.png")
	cells[2].gui_input.emit(_release())
	assert_eq(shop._inspect.title_label.text, "Bone die · Wild on 6", "tap a die to inspect it")
