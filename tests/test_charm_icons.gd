extends GutTest
## add-charm-icons: every catalog charm has its medallion, icons appear wherever a
## charm is shown, and a charm that changed the score is recorded for the pulse.

const THROW_SCENE := preload("res://scenes/throw/throw_scene.tscn")
const SHOP_SCENE := preload("res://scenes/shop/shop_scene.tscn")
const WINDOW := 2.5


func _all_charms() -> Array[CharmEffect]:
	var out: Array[CharmEffect] = []
	for f in DirAccess.get_files_at("res://resources/charms/"):
		if f.ends_with(".tres") or f.ends_with(".tres.remap"):
			out.append(load("res://resources/charms/" + f.trim_suffix(".remap")) as CharmEffect)
	return out


func _result(faces: Array, lock_windows: Array) -> ThrowResult:
	var r := ThrowResult.new()
	for i in faces.size():
		r.faces.append(int(faces[i]))
		r.locked_order.append(i)
		r.lock_windows.append(int(lock_windows[i]))
	return r


func test_every_catalog_charm_has_a_256_icon() -> void:
	var charms := _all_charms()
	assert_eq(charms.size(), 12)
	for c in charms:
		assert_not_null(c.icon, "%s has an icon" % c.display_name)
		if c.icon != null:
			assert_eq(c.icon.get_size(), Vector2(256, 256), "%s icon is 256²" % c.display_name)


func test_triggers_record_only_charms_that_changed_the_score() -> void:
	var inv := CharmInventory.new()
	inv.add_charm(CharmLoaded.new())  # slot 0: no 6 locked → silent
	inv.add_charm(CharmHairTrigger.new())  # slot 1: two dice in Window 1 → +10 chips
	inv.add_charm(CharmSnakeCharmer.new())  # slot 2: not snake eyes → silent
	var bd := ScoringEngine.new().score(_result([4, 4], [1, 1]), ScoringConfig.new(), WINDOW, false, inv)
	assert_eq(bd.charm_triggers.size(), 1, "one charm fired")
	assert_eq(int(bd.charm_triggers[0].slot), 1)
	assert_eq(int(bd.charm_triggers[0].chips), 10)


func test_snake_charmer_rewrite_counts_as_a_trigger() -> void:
	var inv := CharmInventory.new()
	inv.add_charm(CharmSnakeCharmer.new())
	var bd := ScoringEngine.new().score(_result([1, 1], [1, 1]), ScoringConfig.new(), WINDOW, false, inv)
	assert_eq(bd.charm_triggers.size(), 1, "rewriting combo mult is a trigger")


func _throw_scene() -> Control:
	RunCoordinator.new_run(9)
	RunCoordinator.inventory.add_charm(load("res://resources/charms/quick_draw.tres"))
	RunCoordinator.inventory.add_charm(load("res://resources/charms/loaded.tres"))
	var scene: Control = THROW_SCENE.instantiate()
	add_child_autofree(scene)
	scene.ante_cleared.disconnect(RunCoordinator.on_ante_cleared)
	return scene


func test_slots_show_medallions_and_pulse() -> void:
	var scene := _throw_scene()
	var loaded: CharmEffect = RunCoordinator.inventory.iter_charms()[1]
	assert_same(scene._charm_slots[1].icon, loaded.icon, "slot shows the charm's icon")
	assert_null(scene._charm_slots[3].icon, "empty slot has no icon")
	var t: Tween = scene._pulse_charm(1)
	t.pause()  # step it by hand: frame-time independent
	t.custom_step(0.08)
	assert_gt(scene._charm_slots[1].scale.x, 1.2, "triggered slot pops")
	t.custom_step(1.0)
	assert_almost_eq(scene._charm_slots[1].scale.x, 1.0, 0.01, "and settles")


func test_shop_cards_and_owned_row_show_icons() -> void:
	RunCoordinator.new_run(3)
	RunCoordinator.inventory.add_charm(load("res://resources/charms/loaded.tres"))
	var shop: Control = SHOP_SCENE.instantiate()
	add_child_autofree(shop)
	assert_eq(shop._owned_icons.get_child_count(), CharmInventory.MAX_SLOTS, "five sockets in the owned row")
	assert_same((shop._owned_icons.get_child(0) as TextureRect).texture,
		RunCoordinator.inventory.iter_charms()[0].icon)
	for i in shop._buy_buttons.size():
		var card := shop._buy_buttons[i].get_parent().get_parent() as Control
		var has_badge := not card.find_children("*", "TextureRect", true, false).is_empty()
		assert_true(has_badge, "offer %d shows an icon (charm, die or trinket)" % i)


func test_end_panel_shows_the_build() -> void:
	var scene := _throw_scene()
	scene._show_end_panel(false)
	assert_eq(scene._end_build.get_child_count(), 5)
	assert_same((scene._end_build.get_child(0) as TextureRect).texture,
		RunCoordinator.inventory.iter_charms()[0].icon)


# --- add-shop-icons ---

func test_every_sellable_item_has_a_256_icon() -> void:
	var paths := [
		"res://resources/dice_materials/iron.tres", "res://resources/dice_materials/glass.tres",
		"res://resources/trinkets/re_tumble.tres", "res://resources/trinkets/freeze_timer.tres",
		"res://resources/carved_dice/wild_6_bone.tres", "res://resources/carved_dice/gem_5_bone.tres",
		"res://resources/carved_dice/spark_4_bone.tres",
	]
	for p in paths:
		var icon: Texture2D = load(p).get("icon")
		assert_not_null(icon, "%s has an icon" % p)
		if icon != null:
			assert_eq(icon.get_size(), Vector2(256, 256), "%s icon is 256²" % p)


func test_trinket_buttons_show_their_chip() -> void:
	var scene := _throw_scene()
	RunCoordinator.trinket_inventory.add_trinket(load("res://resources/trinkets/freeze_timer.tres"))
	scene._rebuild_trinket_buttons()
	var btn := scene._trinket_row.get_child(scene._trinket_row.get_child_count() - 1) as Button
	assert_eq(btn.icon.resource_path, "res://assets/shop/freeze_timer.png")
