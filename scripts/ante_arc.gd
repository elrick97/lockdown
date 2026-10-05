class_name AnteArc
extends RefCounted

signal ante_advanced(new_ante: int, target: int)
signal run_won
signal run_lost

var current_ante: int = 1

var _config: AnteConfig
var _ante_count: int
var _run_done: bool = false


func _init(config: AnteConfig) -> void:
	_config = config
	_ante_count = config.targets.size()


func target_for(ante: int) -> int:
	return _config.targets[ante - 1]


func is_run_done() -> bool:
	return _run_done


func on_round_won() -> void:
	if _run_done:
		return
	if current_ante >= _ante_count:
		_run_done = true
		run_won.emit()
	else:
		current_ante += 1
		ante_advanced.emit(current_ante, target_for(current_ante))


func on_round_lost() -> void:
	if _run_done:
		return
	_run_done = true
	run_lost.emit()


## Silently advances the ante (no ante_advanced signal). RunCoordinator handles
## the scene transition directly so there is no double-transition with
## ThrowScene's ante_cleared path.
func skip_round() -> void:
	if _run_done:
		return
	if current_ante >= _ante_count:
		_run_done = true
		run_won.emit()
	else:
		current_ante += 1
