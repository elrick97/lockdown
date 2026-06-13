class_name ScoringConfig
extends Resource
## All scoring tunables (combo-scoring + heat specs). The M0 playtest tunes
## this .tres file, never the engine. ComboType order doubles as the tie-break
## rank: higher enum value outranks lower.

enum ComboType { PAIR, TWO_PAIR, TRIPLE, SMALL_STRAIGHT, FULL_HOUSE, QUAD, LARGE_STRAIGHT, QUINT }

@export var pair_chips: int = 10
@export var pair_mult: int = 1
@export var two_pair_chips: int = 25
@export var two_pair_mult: int = 2
@export var triple_chips: int = 30
@export var triple_mult: int = 2
@export var small_straight_chips: int = 30
@export var small_straight_mult: int = 2
@export var full_house_chips: int = 50
@export var full_house_mult: int = 3
@export var quad_chips: int = 60
@export var quad_mult: int = 4
@export var large_straight_chips: int = 80
@export var large_straight_mult: int = 5
@export var quint_chips: int = 100
@export var quint_mult: int = 8

@export var base_mult: int = 1
@export var heat_min: float = 1.0
@export var heat_max: float = 1.5
@export var steady_heat: float = 1.25


func get_chips(type: ComboType) -> int:
	match type:
		ComboType.PAIR: return pair_chips
		ComboType.TWO_PAIR: return two_pair_chips
		ComboType.TRIPLE: return triple_chips
		ComboType.SMALL_STRAIGHT: return small_straight_chips
		ComboType.FULL_HOUSE: return full_house_chips
		ComboType.QUAD: return quad_chips
		ComboType.LARGE_STRAIGHT: return large_straight_chips
		ComboType.QUINT: return quint_chips
	return 0


func get_mult(type: ComboType) -> int:
	match type:
		ComboType.PAIR: return pair_mult
		ComboType.TWO_PAIR: return two_pair_mult
		ComboType.TRIPLE: return triple_mult
		ComboType.SMALL_STRAIGHT: return small_straight_mult
		ComboType.FULL_HOUSE: return full_house_mult
		ComboType.QUAD: return quad_mult
		ComboType.LARGE_STRAIGHT: return large_straight_mult
		ComboType.QUINT: return quint_mult
	return 0


func get_combo_name(type: ComboType) -> String:
	match type:
		ComboType.PAIR: return "Pair"
		ComboType.TWO_PAIR: return "Two Pair"
		ComboType.TRIPLE: return "Triple"
		ComboType.SMALL_STRAIGHT: return "Small Straight"
		ComboType.FULL_HOUSE: return "Full House"
		ComboType.QUAD: return "Quad"
		ComboType.LARGE_STRAIGHT: return "Large Straight"
		ComboType.QUINT: return "Quint"
	return "?"
