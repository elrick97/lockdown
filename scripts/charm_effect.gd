class_name CharmEffect
extends Resource
## Base class for all charm effects (charm-effect spec). Each charm is a
## GDScript extending this class, saved as a .tres resource. Adding a charm
## never requires editing the scoring engine or throw controller.

@export var display_name: String = ""
@export var description: String = ""
@export var cost: int = 0
## Medallion shown in slots, shop cards and the end panel (add-charm-icons).
@export var icon: Texture2D


func on_throw(ctx: CharmContext) -> void:
	pass


func on_window(window_index: int, ctx: CharmContext) -> void:
	pass


func on_lock(die_index: int, face: int, window_index: int, ctx: CharmContext) -> void:
	pass


func on_score(breakdown: ScoreBreakdown, ctx: CharmContext) -> void:
	pass
