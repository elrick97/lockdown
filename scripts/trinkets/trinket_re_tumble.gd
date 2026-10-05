class_name TrinketReTumble
extends Trinket

func activate(controller: ThrowController) -> void:
	controller.force_reroll_unlocked()
