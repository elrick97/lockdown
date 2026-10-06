extends GutTest
## add-ante-intro-card: each ante opens with its target, reward and rule in plain
## words; the boss rule shows in the HUD; the shop previews the next ante.

const THROW_SCENE := preload("res://scenes/throw/throw_scene.tscn")
const SHOP_SCENE := preload("res://scenes/shop/shop_scene.tscn")


func after_each() -> void:
	RunCoordinator.new_run()


func _scene(ante: int) -> Control:
	RunCoordinator.new_run(21)
	RunCoordinator.arc.current_ante = ante
	var scene: Control = THROW_SCENE.instantiate()
	add_child_autofree(scene)
	scene.ante_cleared.disconnect(RunCoordinator.on_ante_cleared)
	return scene


func test_open_ante_intro_states_target_and_reward() -> void:
	var scene := _scene(1)
	assert_true(scene._intro.visible, "intro shows before the first throw")
	assert_eq(scene._intro_target.text, "TARGET %d" % scene._round.target)
	assert_true(scene._intro_reward.text.begins_with("Win: 4g + 1g per spare throw"))
	assert_false(scene._skip_button.visible, "no skip outside Risk")
	assert_eq(scene._throw_label.text, "Throw 1 of 3")
	assert_eq(scene._total_label.text, "Total 0 · Target %d" % scene._round.target)


func test_boss_rule_is_stated_in_plain_words_and_in_the_hud() -> void:
	var scene := _scene(3)
	assert_true(scene._intro_rule.text.contains("lock windows halved (1.25 s)"), scene._intro_rule.text)
	assert_true(scene._ante_label.text.contains("BOSS ROUND"))
	assert_true(scene._ante_label.text.contains("½ WINDOWS"), "boss chip in the HUD")


func test_risk_intro_carries_the_skip_trade_off() -> void:
	var scene := _scene(2)
	assert_true(scene._skip_button.visible)
	assert_true(scene._skip_button.get_parent() == scene._intro, "SKIP lives on the intro card")
	assert_true(scene._intro_rule.text.contains("skip this round for +3g"), scene._intro_rule.text)


func test_play_or_throw_dismisses_and_label_reopens_between_throws() -> void:
	var scene := _scene(1)
	scene._intro_play.pressed.emit()
	assert_false(scene._intro.visible, "PLAY dismisses")
	scene._reopen_intro()
	assert_true(scene._intro.visible, "tapping the ante label reopens it while idle")
	scene._on_throw_pressed()
	assert_false(scene._intro.visible, "THROW dismisses too")
	scene._reopen_intro()
	assert_false(scene._intro.visible, "never during a throw")


func test_shop_previews_the_next_ante() -> void:
	RunCoordinator.new_run(4)
	RunCoordinator.arc.current_ante = 3
	var shop: Control = SHOP_SCENE.instantiate()
	add_child_autofree(shop)
	assert_eq(shop._next_label.text, "NEXT: ANTE 3 · BOSS ROUND · TARGET 700 · ½ WINDOWS")
