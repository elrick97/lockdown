extends GutTest
## Scene-level integration tests for ShopScene (shop-scene spec). Exercises the
## real .tscn and the real _on_buy_pressed() path for all 4 offer kinds —
## charm/die/trinket/carved_die — which the pure-logic unit tests never touch.

const SCENE := preload("res://scenes/shop/shop_scene.tscn")


func before_each() -> void:
	RunCoordinator.start_run()
	RunCoordinator.ledger.earn(100)


func _inject_offer(scene: Control, index: int, kind: String, res: Resource) -> void:
	var offer := ShopOffer.make(ShopOffer.Type.CHARM_STUB, res.display_name, res.cost)
	scene._offers[index] = offer
	scene._offer_charms[index] = res if kind == "charm" else null
	scene._offer_materials[index] = res if kind == "die" else null
	scene._offer_trinkets[index] = res if kind == "trinket" else null
	scene._offer_carved[index] = res if kind == "carved_die" else null


func test_item_pool_includes_all_four_offer_kinds() -> void:
	var scene: Control = SCENE.instantiate()
	add_child_autofree(scene)
	var pool: Array = scene._build_item_pool()
	var kinds: Dictionary = {}
	for item in pool:
		kinds[item.kind] = true
	assert_true(kinds.has("charm"), "pool includes charm offers")
	assert_true(kinds.has("die"), "pool includes die (material) offers")
	assert_true(kinds.has("trinket"), "pool includes trinket offers")
	assert_true(kinds.has("carved_die"), "pool includes carved die offers")


func test_buying_die_offer_adds_material_to_bag() -> void:
	var scene: Control = SCENE.instantiate()
	add_child_autofree(scene)
	var mat := load("res://resources/dice_materials/iron.tres") as DiceMaterial
	_inject_offer(scene, 0, "die", mat)
	var before := RunCoordinator.bag.available()
	var gold_before := RunCoordinator.ledger.gold
	scene._on_buy_pressed(0)
	assert_eq(RunCoordinator.bag.available(), before + 1, "Iron die added to bag")
	assert_eq(RunCoordinator.ledger.gold, gold_before - mat.cost, "gold deducted by cost")
	assert_true(scene._offers[0].sold, "offer marked sold")


func test_buying_trinket_offer_adds_to_trinket_inventory() -> void:
	var scene: Control = SCENE.instantiate()
	add_child_autofree(scene)
	var trinket := load("res://resources/trinkets/re_tumble.tres") as Trinket
	_inject_offer(scene, 0, "trinket", trinket)
	scene._on_buy_pressed(0)
	var held := RunCoordinator.trinket_inventory.iter_trinkets()
	assert_eq(held.size(), 1, "trinket inventory gained one trinket")
	assert_eq(held[0].display_name, trinket.display_name)


func test_buying_carved_die_offer_adds_carved_die_to_bag() -> void:
	var scene: Control = SCENE.instantiate()
	add_child_autofree(scene)
	var carved := load("res://resources/carved_dice/wild_6_bone.tres") as CarvedDieOffer
	_inject_offer(scene, 0, "carved_die", carved)
	var before := RunCoordinator.bag.available()
	scene._on_buy_pressed(0)
	assert_eq(RunCoordinator.bag.available(), before + 1, "carved die added to bag")
	var drawn := RunCoordinator.bag.draw(RunCoordinator.bag.available(), RngCore.new(1))
	var found := false
	for d in drawn:
		if d.carved_face == carved.carved_face and d.carve_type == carved.carve_type:
			found = true
	assert_true(found, "drawn die carries the carved_face/carve_type from the offer")


func test_buying_charm_offer_adds_to_charm_inventory() -> void:
	var scene: Control = SCENE.instantiate()
	add_child_autofree(scene)
	var charm := load("res://resources/charms/quick_draw.tres") as CharmEffect
	_inject_offer(scene, 0, "charm", charm)
	scene._on_buy_pressed(0)
	assert_eq(RunCoordinator.inventory.iter_charms().size(), 1, "charm inventory gained one charm")


func test_trinket_purchase_blocked_when_trinket_inventory_full() -> void:
	var scene: Control = SCENE.instantiate()
	add_child_autofree(scene)
	RunCoordinator.trinket_inventory.add_trinket(Trinket.new())
	RunCoordinator.trinket_inventory.add_trinket(Trinket.new())
	assert_true(RunCoordinator.trinket_inventory.is_full())
	var trinket := load("res://resources/trinkets/freeze_timer.tres") as Trinket
	_inject_offer(scene, 0, "trinket", trinket)
	var gold_before := RunCoordinator.ledger.gold
	scene._on_buy_pressed(0)
	assert_eq(RunCoordinator.ledger.gold, gold_before, "no gold spent when trinket inventory is full")
	assert_false(scene._offers[0].sold, "offer not marked sold when blocked")


func test_die_purchase_not_blocked_by_full_trinket_inventory() -> void:
	var scene: Control = SCENE.instantiate()
	add_child_autofree(scene)
	RunCoordinator.trinket_inventory.add_trinket(Trinket.new())
	RunCoordinator.trinket_inventory.add_trinket(Trinket.new())
	var mat := load("res://resources/dice_materials/glass.tres") as DiceMaterial
	_inject_offer(scene, 0, "die", mat)
	var before := RunCoordinator.bag.available()
	scene._on_buy_pressed(0)
	assert_eq(RunCoordinator.bag.available(), before + 1,
			"die purchase unaffected by a full trinket inventory")


func test_purchase_blocked_when_gold_insufficient() -> void:
	var scene: Control = SCENE.instantiate()
	add_child_autofree(scene)
	RunCoordinator.ledger.gold = 0
	var mat := load("res://resources/dice_materials/iron.tres") as DiceMaterial
	_inject_offer(scene, 0, "die", mat)
	var before := RunCoordinator.bag.available()
	scene._on_buy_pressed(0)
	assert_eq(RunCoordinator.bag.available(), before, "nothing added when gold is insufficient")
	assert_false(scene._offers[0].sold, "offer not marked sold when unaffordable")


func test_already_sold_offer_cannot_be_bought_twice() -> void:
	var scene: Control = SCENE.instantiate()
	add_child_autofree(scene)
	var mat := load("res://resources/dice_materials/iron.tres") as DiceMaterial
	_inject_offer(scene, 0, "die", mat)
	scene._on_buy_pressed(0)
	var after_first := RunCoordinator.bag.available()
	scene._on_buy_pressed(0)
	assert_eq(RunCoordinator.bag.available(), after_first, "second buy on a sold offer is a no-op")


func test_reroll_spends_gold_and_refreshes_offers() -> void:
	var scene: Control = SCENE.instantiate()
	add_child_autofree(scene)
	var gold_before := RunCoordinator.ledger.gold
	scene._on_reroll_pressed()
	assert_eq(RunCoordinator.ledger.gold, gold_before - scene._shop_config.reroll_cost,
			"reroll deducts reroll_cost")
	assert_eq(scene._offers.size(), 3, "reroll repopulates 3 offers")
