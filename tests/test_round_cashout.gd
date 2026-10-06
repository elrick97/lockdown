extends GutTest
## add-round-cashout: the itemised gold always sums to what the shop opens with, and
## the throw screen shows it before the shop.

const THROW_SCENE := preload("res://scenes/throw/throw_scene.tscn")
var _seen: Array = []


func before_each() -> void:
	RunCoordinator.new_run(8)
	_seen.clear()
	RunCoordinator.cashout_ready.connect(_on_cashout)


func after_each() -> void:
	if RunCoordinator.cashout_ready.is_connected(_on_cashout):
		RunCoordinator.cashout_ready.disconnect(_on_cashout)
	RunCoordinator.new_run()


func _on_cashout(c: Dictionary) -> void:
	_seen.append(c)


func _sum(c: Dictionary) -> int:
	var s := 0
	for l in c.lines:
		s += int(l.gold)
	return s


func test_lines_sum_to_the_gold_the_shop_opens_with() -> void:
	for case in [[0, 0], [6, 2], [2, 1], [38, 0], [40, 2]]:
		RunCoordinator.ledger.gold = case[0]
		RunCoordinator.on_ante_cleared(case[1])
		var c: Dictionary = _seen.back()
		assert_eq(c.before, case[0])
		assert_eq(c.after, RunCoordinator.ledger.gold)
		assert_eq(c.before + _sum(c), c.after, "lines add up (gold %d, spare %d)" % case)
		assert_lte(c.after, RunCoordinator.shop_config.max_gold)


func test_breakdown_lines_name_their_source() -> void:
	RunCoordinator.ledger.gold = 6
	RunCoordinator.on_ante_cleared(2)
	var c: Dictionary = _seen.back()
	assert_eq(c.title, "ROUND CLEARED")
	assert_eq(c.lines[0].text, "Round reward")
	assert_eq(int(c.lines[0].gold), 4)
	assert_eq(c.lines[1].text, "Spare throws ×2")
	assert_eq(int(c.lines[1].gold), 2)
	assert_true(String(c.lines[2].text).begins_with("Interest (25% of 12"), c.lines[2].text)
	assert_eq(int(c.lines[2].gold), 3)
	assert_eq(c.after, 15)


func test_risk_skip_cashes_out_with_interest() -> void:
	RunCoordinator.arc.current_ante = 2
	RunCoordinator.ledger.gold = 6
	RunCoordinator.on_risk_skipped()
	var c: Dictionary = _seen.back()
	assert_eq(c.title, "ROUND SKIPPED")
	assert_eq(c.lines[0].text, "Skipped risk round")
	assert_eq(c.after, 11, "6 + 3 skip, then 25% interest (gold-economy spec: every shop visit)")
	assert_eq(c.before + _sum(c), c.after)


func test_throw_screen_shows_the_panel_before_the_shop() -> void:
	var scene: Control = THROW_SCENE.instantiate()
	add_child_autofree(scene)
	scene.ante_cleared.disconnect(RunCoordinator.on_ante_cleared)
	RunCoordinator.ledger.gold = 6
	RunCoordinator.on_ante_cleared(1)
	assert_true(scene._cashout.visible, "panel shown")
	assert_false(scene._throw_button.visible, "THROW hidden behind it")
	assert_eq(scene._cashout_rows.get_child_count(), 3, "base, spare throws, interest")
	assert_true(scene._cashout_continue.pressed.is_connected(RunCoordinator.go_to_shop), "CONTINUE goes to the shop")
	await wait_seconds(2.2)
	assert_eq(scene._cashout_total.text, str(RunCoordinator.ledger.gold), "total counts up to the new gold")
