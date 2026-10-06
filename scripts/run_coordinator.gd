extends Node
## Run-scoped coordinator (ante-arc spec). Autoload singleton that owns AnteArc
## and GoldLedger across scene transitions so ThrowScene and ShopScene share
## the same run state without tight coupling.

var arc: AnteArc
var ledger: GoldLedger
var inventory: CharmInventory
var trinket_inventory: TrinketInventory
var bag: DiceBag
var config: AnteConfig = preload("res://resources/ante_arc.tres")
var shop_config: ShopConfig = preload("res://resources/shop_config.tres")
var _throw_config: ThrowConfig = preload("res://resources/throw_config.tres")

var _run_active: bool = false
## Itemised gold for the round-cleared panel (add-round-cashout): emitted after the
## gold is credited, instead of jumping straight to the shop.
## { title: String, lines: [{ text, gold }], before: int, after: int }
signal cashout_ready(cashout: Dictionary)
var last_cashout: Dictionary = {}
## Run summary for the end-of-run panel (run-flow spec). Presentation data only.
var best_throw: int = 0


## Call once per run (ThrowScene._ready calls this on first launch or after a
## run-won/lost when the player restarts). Safe to call again — resets state.
## The RNG is seeded here and only here (seeded-rng spec): pass 0 to generate a
## seed, read it back from RngService.run_seed to reproduce the run.
func start_run(seed_value: int = 0) -> void:
	RngService.start_run(seed_value)
	arc = AnteArc.new(config)
	ledger = GoldLedger.new()
	inventory = CharmInventory.new()
	trinket_inventory = TrinketInventory.new()
	bag = DiceBag.new(_throw_config.starting_bag_size)
	best_throw = 0
	_run_active = true


## A fresh run from the start screen or the end-of-run panel (run-flow spec):
## the only reset path, so PLAY and NEW RUN can't drift apart.
func new_run(seed_value: int = 0) -> void:
	end_run()
	start_run(seed_value)


## Called when a throw's cascade finishes; keeps the run's best single throw.
func record_throw(score: int) -> void:
	best_throw = maxi(best_throw, score)


## Called by ThrowScene when ante_advanced fires. Credits gold, applies
## interest, then transitions to ShopScene.
func on_ante_cleared(throws_left: int) -> void:
	if not _run_active:
		return
	var before := ledger.gold
	var lines: Array = [{"text": "Round reward", "gold": shop_config.base_gold_per_ante}]
	if throws_left > 0:
		lines.append({"text": "Spare throws ×%d" % throws_left,
			"gold": throws_left * shop_config.gold_per_leftover_throw})
	var earned := shop_config.base_gold_per_ante \
		+ throws_left * shop_config.gold_per_leftover_throw
	ledger.earn(earned)
	_finish_cashout("ROUND CLEARED", before, lines)


## Interest is applied once per shop visit (gold-economy spec), then the itemised
## breakdown goes to the throw screen's round-cleared panel.
func _finish_cashout(title: String, before: int, lines: Array) -> void:
	var pre_interest := ledger.gold
	ledger.apply_interest(shop_config)
	var interest := ledger.gold - pre_interest
	lines.append({"text": "Interest (%d%% of %d, max %d)" % [roundi(shop_config.interest_rate * 100.0),
		pre_interest, shop_config.max_gold], "gold": interest})
	last_cashout = {"title": title, "lines": lines, "before": before, "after": ledger.gold}
	cashout_ready.emit(last_cashout)


## The round-cleared panel's CONTINUE: on to the shop.
func go_to_shop() -> void:
	last_cashout = {}
	get_tree().change_scene_to_file("res://scenes/shop/shop_scene.tscn")


## Called by ShopScene CONTINUE button. Transitions back to the throw loop.
func on_shop_continued() -> void:
	get_tree().change_scene_to_file("res://scenes/throw/throw_scene.tscn")


## Called by ThrowScene SKIP button on Risk antes. Earns reduced gold and
## advances past the risk round.
func on_risk_skipped() -> void:
	if not _run_active:
		return
	var ante_config: AnteConfig = preload("res://resources/ante_arc.tres")
	var before := ledger.gold
	ledger.earn(ante_config.skip_reward_gold)
	arc.skip_round()
	if not arc.is_run_done():
		_finish_cashout("ROUND SKIPPED", before,
			[{"text": "Skipped risk round", "gold": ante_config.skip_reward_gold}])


## Called when the run ends (won or lost) so the next start_run is clean.
func end_run() -> void:
	_run_active = false
