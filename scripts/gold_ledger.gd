class_name GoldLedger
extends RefCounted
## Mutable run-scoped gold tracker (gold-economy spec). Pure headless — no scene
## dependency. Owned by RunCoordinator and passed by reference to ShopScene.

var gold: int = 0


func earn(amount: int) -> void:
	gold += amount


func apply_interest(config: ShopConfig) -> void:
	gold += floori(gold * config.interest_rate)
	gold = mini(gold, config.max_gold)


func can_afford(cost: int) -> bool:
	return gold >= cost


func spend(cost: int) -> bool:
	if not can_afford(cost):
		return false
	gold -= cost
	return true
