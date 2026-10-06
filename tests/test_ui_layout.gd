extends GutTest
## ui-theme spec: shared theme, thumb-zone placement and tap size, owned build on
## the throw screen, shop cards with descriptions.

const THROW_SCENE := preload("res://scenes/throw/throw_scene.tscn")
const SHOP_SCENE := preload("res://scenes/shop/shop_scene.tscn")
const START_SCENE := preload("res://scenes/start/start_scene.tscn")
const MIN_PX := 126.0  # 48 dp
const THUMB_Y := 2400.0 * 0.6  # bottom 40%
const SHOP_Y := 2400.0 * 0.45  # bottom 55%


func _assert_tappable(c: Control, min_y: float, what: String) -> void:
	var r := c.get_global_rect()
	assert_gte(r.size.y, MIN_PX, "%s tall enough (%.0f px)" % [what, r.size.y])
	assert_gte(r.size.x, MIN_PX, "%s wide enough (%.0f px)" % [what, r.size.x])
	assert_gte(r.position.y, min_y, "%s in the thumb zone (y %.0f)" % [what, r.position.y])


func _throw_scene(ante: int = 1) -> Control:
	RunCoordinator.new_run(9)
	RunCoordinator.arc.current_ante = ante
	RunCoordinator.inventory.add_charm(load("res://resources/charms/quick_draw.tres"))
	RunCoordinator.inventory.add_charm(load("res://resources/charms/loaded.tres"))
	RunCoordinator.trinket_inventory.add_trinket(load("res://resources/trinkets/re_tumble.tres"))
	RunCoordinator.trinket_inventory.add_trinket(load("res://resources/trinkets/freeze_timer.tres"))
	var scene: Control = THROW_SCENE.instantiate()
	add_child_autofree(scene)
	scene.ante_cleared.disconnect(RunCoordinator.on_ante_cleared)
	return scene


func test_every_screen_uses_the_shared_theme() -> void:
	var start: Control = START_SCENE.instantiate()
	add_child_autofree(start)
	assert_same(start.theme, UiStyle.theme(), "start")
	assert_same(_throw_scene().theme, UiStyle.theme(), "throw")
	var shop: Control = SHOP_SCENE.instantiate()
	add_child_autofree(shop)
	assert_same(shop.theme, UiStyle.theme(), "shop")


func test_throw_screen_controls_in_thumb_zone() -> void:
	var scene := _throw_scene(2)  # Risk ante: SKIP shown
	scene._rebuild_trinket_buttons()
	scene._trinket_row.visible = true  # as during a lock window
	await wait_frames(2)
	_assert_tappable(scene._throw_button, THUMB_Y, "THROW")
	_assert_tappable(scene._skip_button, THUMB_Y, "SKIP")
	for slot in scene._charm_slots:
		_assert_tappable(slot, THUMB_Y, "charm slot")
	for b in scene._trinket_row.get_children():
		_assert_tappable(b as Control, THUMB_Y, "trinket button")


func test_charm_row_shows_owned_build_and_effects() -> void:
	var scene := _throw_scene()
	assert_eq(scene._charm_slots.size(), 5)
	assert_eq(scene._charm_slots[0].text, "Quick Draw")
	assert_eq(scene._charm_slots[1].text, "Loaded")
	assert_true(scene._charm_slots[2].disabled, "empty slot is disabled")
	scene._charm_slots[1].pressed.emit()
	assert_true(scene._status.text.begins_with("Loaded: "), "tapping shows the effect")


func test_shop_cards_show_descriptions_and_owned_line() -> void:
	RunCoordinator.new_run(3)
	RunCoordinator.inventory.add_charm(load("res://resources/charms/quick_draw.tres"))
	var shop: Control = SHOP_SCENE.instantiate()
	add_child_autofree(shop)
	await wait_frames(2)
	assert_eq(shop._owned_label.text, "Charms 1 / 5: Quick Draw")
	assert_eq(shop._buy_buttons.size(), 3, "three offers")
	for i in shop._buy_buttons.size():
		var card := shop._buy_buttons[i].get_parent().get_parent() as Control
		var body: Label = card.find_children("*", "Label", true, false)[1]
		assert_ne(body.text, "", "offer %d shows its effect" % i)
		_assert_tappable(shop._buy_buttons[i], SHOP_Y, "BUY %d" % i)
	_assert_tappable(shop._reroll_button, SHOP_Y, "RE-ROLL")
	_assert_tappable(shop._continue_button, SHOP_Y, "CONTINUE")


# --- Smoke Room table (add-smoke-room-table) ---

func _overlay_of(screen: Node) -> SmokeOverlay:
	return screen.find_children("*", "SmokeOverlay", false, false)[0] as SmokeOverlay


func test_every_screen_has_backdrop_and_input_transparent_overlay() -> void:
	var start: Control = START_SCENE.instantiate()
	add_child_autofree(start)
	var shop: Control = SHOP_SCENE.instantiate()
	add_child_autofree(shop)
	for screen in [start, _throw_scene(), shop]:
		var overlay := _overlay_of(screen)
		assert_eq(overlay.rect.mouse_filter, Control.MOUSE_FILTER_IGNORE, "overlay never takes input")
		assert_true(screen.get_child(0) is TextureRect, "backdrop drawn first")


# --- Smoke Room UI kit (add-smoke-room-ui-art) ---

func _kit_box(t: Theme, item: String, type: StringName) -> void:
	var sb := t.get_stylebox(item, type)
	assert_true(sb is StyleBoxTexture, "%s/%s is a kit texture" % [type, item])
	if sb is StyleBoxTexture:
		assert_true((sb as StyleBoxTexture).texture.resource_path.begins_with(UiStyle.UI_DIR),
			"%s/%s texture comes from the UI kit" % [type, item])


func test_theme_chrome_is_the_rendered_kit() -> void:
	var t := UiStyle.theme()
	for type in [&"Button", &"ThrowButton", &"SlotButton"]:
		for item in ["normal", "hover", "pressed", "disabled"]:
			_kit_box(t, item, type)
	for type in [&"Panel", &"PanelContainer", &"PlaquePanel"]:
		_kit_box(t, "panel", type)
	var primary := t.get_stylebox("normal", &"ThrowButton") as StyleBoxTexture
	var pressed := t.get_stylebox("pressed", &"ThrowButton") as StyleBoxTexture
	var disabled := t.get_stylebox("disabled", &"ThrowButton") as StyleBoxTexture
	assert_ne(primary.texture, pressed.texture, "pressed has its own art")
	assert_ne(primary.texture, disabled.texture, "disabled has its own art")


func test_timer_and_plaques_use_the_kit() -> void:
	var scene := _throw_scene()
	assert_true(scene._timer_track is NinePatchRect, "timer frame is a 9-patch")
	assert_eq(scene._timer_track.texture.resource_path, UiStyle.UI_DIR + "timer_frame.png")
	var fill := scene._timer_bar.get_child(0) as NinePatchRect
	assert_not_null(fill, "timer fill is a 9-patch child of the bar")
	assert_eq(fill.texture.resource_path, UiStyle.UI_DIR + "timer_fill.png")
	assert_eq(scene._total_plaque.theme_type_variation, &"PlaquePanel")
	var shop: Control = SHOP_SCENE.instantiate()
	add_child_autofree(shop)
	assert_eq(shop._gold_panel.theme_type_variation, &"PlaquePanel")


func test_felt_fills_the_tray_behind_the_dice() -> void:
	var scene := _throw_scene()
	await wait_frames(2)
	assert_eq(scene._felt.get_global_rect(), scene._tray.get_global_rect(), "felt covers the tray band")
	assert_lt(scene._felt.get_index(), scene._tumbler.get_index(), "felt is behind the dice")
