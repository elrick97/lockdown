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
	_run_active = true


## Called by ThrowScene when ante_advanced fires. Credits gold, applies
## interest, then transitions to ShopScene.
func on_ante_cleared(throws_left: int) -> void:
	if not _run_active:
		return
	var earned := shop_config.base_gold_per_ante \
		+ throws_left * shop_config.gold_per_leftover_throw
	ledger.earn(earned)
	ledger.apply_interest(shop_config)
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
	ledger.earn(ante_config.skip_reward_gold)
	arc.skip_round()
	if not arc.is_run_done():
		get_tree().change_scene_to_file("res://scenes/shop/shop_scene.tscn")


## Called when the run ends (won or lost) so the next start_run is clean.
func end_run() -> void:
	_run_active = false
