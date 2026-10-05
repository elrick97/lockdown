extends GutTest
## Headless unit tests for GoldLedger (gold economy spec).

var _cfg: ShopConfig


func before_each() -> void:
	_cfg = ShopConfig.new()
	_cfg.interest_rate = 0.25
	_cfg.max_gold = 40


func test_earn_adds_gold() -> void:
	var ledger := GoldLedger.new()
	ledger.earn(5)
	assert_eq(ledger.gold, 5, "earn adds the given amount")


func test_interest_adds_floor_of_rate() -> void:
	var ledger := GoldLedger.new()
	ledger.earn(10)
	ledger.apply_interest(_cfg)  # 10 * 0.25 = 2.5 → floor 2
	assert_eq(ledger.gold, 12, "interest is floored and added")


func test_interest_caps_at_max_gold() -> void:
	var ledger := GoldLedger.new()
	ledger.earn(38)
	ledger.apply_interest(_cfg)  # 38 * 0.25 = 9.5 → floor 9 → 47, capped to 40
	assert_eq(ledger.gold, 40, "gold does not exceed max_gold after interest")


func test_spend_deducts_and_returns_true() -> void:
	var ledger := GoldLedger.new()
	ledger.earn(6)
	var ok := ledger.spend(4)
	assert_true(ok, "spend returns true when funds are available")
	assert_eq(ledger.gold, 2, "gold is deducted after successful spend")


func test_spend_fails_when_insufficient() -> void:
	var ledger := GoldLedger.new()
	ledger.earn(2)
	var ok := ledger.spend(5)
	assert_false(ok, "spend returns false when funds are insufficient")
	assert_eq(ledger.gold, 2, "gold unchanged after failed spend")


func test_reroll_deduction() -> void:
	var ledger := GoldLedger.new()
	ledger.earn(3)
	var ok := ledger.spend(_cfg.reroll_cost)
	assert_true(ok, "reroll deduction succeeds with enough gold")
	assert_eq(ledger.gold, 3 - _cfg.reroll_cost, "reroll cost deducted correctly")
