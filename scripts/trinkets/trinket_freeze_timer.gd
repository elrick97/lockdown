class_name TrinketFreezeTimer
extends Trinket

const FREEZE_DURATION_S := 2.0

func activate(controller: ThrowController) -> void:
	controller.freeze_window(FREEZE_DURATION_S)
