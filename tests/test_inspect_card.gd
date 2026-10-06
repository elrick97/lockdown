extends GutTest
## add-inspect-card: one shared card shows any item's data, wraps long rules inside
## the card, dismisses on any tap, and never blocks a die tap during a lock window.

const THROW_SCENE := preload("res://scenes/throw/throw_scene.tscn")
const SHOP_SCENE := preload("res://scenes/shop/shop_scene.tscn")


func after_each() -> void:
	RunCoordinator.new_run()



func test_card_shows_item_data_for_every_family() -> void:
	var card := InspectCard.new()
	add_child_autofree(card)
	var items := {
		"res://resources/charms/snake_charmer.tres": "CHARM",
		"res://resources/dice_materials/glass.tres": "GLASS DIE",
		"res://resources/carved_dice/wild_6_bone.tres": "CARVED DIE",
		"res://resources/trinkets/freeze_timer.tres": "TRINKET",
	}
	for path: String in items:
		var res := load(path)
		card.show_item(res, 1500.0, true)
		assert_true(card.visible)
		assert_eq(card.title_label.text, res.get("display_name"))
		assert_true(card.tag_label.text.begins_with(items[path]), card.tag_label.text)
		assert_eq(card.body_label.text, res.get("description"))
		assert_true(card.cost_label.visible, "cost shown in the shop")


func test_long_rule_wraps_inside_the_card() -> void:
	var card := InspectCard.new()
	add_child_autofree(card)
	card.show_item(load("res://resources/carved_dice/spark_4_bone.tres"), 1500.0)
	await wait_process_frames(2)
	assert_gt(card.body_label.get_line_count(), 1, "long text wraps")
	assert_lte(card.size.x, InspectCard.WIDTH + 1.0, "card keeps its width")
	assert_almost_eq(card.position.y + card.size.y, 1500.0, 1.0, "bottom edge where asked")


func test_any_tap_dismisses_without_eating_it() -> void:
	var card := InspectCard.new()
	add_child_autofree(card)
	card.show_item(load("res://resources/charms/loaded.tres"), 1500.0)
	var ev := InputEventMouseButton.new()
	ev.button_index = MOUSE_BUTTON_LEFT
	ev.pressed = true
	card._input(ev)
	assert_false(card.visible, "dismissed")
	assert_eq(card.mouse_filter, Control.MOUSE_FILTER_IGNORE, "the card never takes input")


func test_die_tap_still_locks_with_the_card_open() -> void:
	RunCoordinator.new_run(1234)
	RunCoordinator.inventory.add_charm(load("res://resources/charms/loaded.tres"))
	var scene: Control = THROW_SCENE.instantiate()
	var cfg := ThrowConfig.new()
	cfg.tumble_duration_s = 0.05
	cfg.lock_window_duration_s = 30.0
	scene._config = cfg
	add_child_autofree(scene)
	scene.ante_cleared.disconnect(RunCoordinator.on_ante_cleared)
	scene._on_throw_pressed()
	await wait_until(func() -> bool: return scene._controller.state == ThrowController.State.LOCK_WINDOW, 2.0)
	scene._charm_slots[0].pressed.emit()
	assert_true(scene._inspect.visible)
	scene._try_lock_at(scene._tumbler.die_rect(2).get_center())
	assert_true(scene._controller.locked[2], "the die locks while the card is open")
	assert_true(scene._controller.time_remaining() > 0.0 and not get_tree().paused, "nothing paused")


func test_shop_medallions_and_offers_open_the_card() -> void:
	RunCoordinator.new_run(3)
	RunCoordinator.inventory.add_charm(load("res://resources/charms/collector.tres"))
	var shop: Control = SHOP_SCENE.instantiate()
	add_child_autofree(shop)
	var release := InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_LEFT
	release.pressed = false
	(shop._owned_icons.get_child(0) as Control).gui_input.emit(release)
	assert_eq(shop._inspect.title_label.text, "Collector")
	var card := shop._buy_buttons[0].get_parent().get_parent() as Control
	var badge := card.find_children("*", "TextureRect", true, false)[0] as Control
	badge.gui_input.emit(release)
	assert_true(shop._inspect.visible)
	assert_true(shop._inspect.cost_label.visible, "offers show their cost")


func test_end_panel_build_opens_the_card() -> void:
	RunCoordinator.new_run(5)
	RunCoordinator.inventory.add_charm(load("res://resources/charms/precision.tres"))
	var scene: Control = THROW_SCENE.instantiate()
	add_child_autofree(scene)
	scene.ante_cleared.disconnect(RunCoordinator.on_ante_cleared)
	scene._show_end_panel(false)
	var release := InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_LEFT
	release.pressed = false
	(scene._end_build.get_child(0) as Control).gui_input.emit(release)
	assert_eq(scene._inspect.title_label.text, "Precision")
	assert_gt(scene._inspect.get_index(), scene._end_panel.get_index(), "card draws over the end panel")
