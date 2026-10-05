class_name ShopConfig
extends Resource
## Tunables for the gold economy and shop (gold-economy + shop-scene specs).
## Adjust the .tres file to tune without touching engine code.

@export var base_gold_per_ante: int = 4
@export var gold_per_leftover_throw: int = 1
@export var interest_rate: float = 0.25
@export var max_gold: int = 40
@export var reroll_cost: int = 1
@export var offer_slots: int = 3
