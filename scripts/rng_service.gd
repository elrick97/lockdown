extends Node
## Autoload facade over RngCore. Gameplay code calls this; never randi()/randf()
## or its own RandomNumberGenerator. Canonical streams: RngCore.STREAM_DICE,
## STREAM_SHOP, STREAM_BAG (new streams may be added by name as systems need them).

var _core: RngCore = RngCore.new()


## Starts a new run. Pass 0 (default) to generate a seed; read it back via
## run_seed for display/logging so any run can be reproduced.
func start_run(seed_value: int = 0) -> void:
	_core = RngCore.new(seed_value)


var run_seed: int:
	get:
		return _core.run_seed


func randi_range(stream: String, from: int, to: int) -> int:
	return _core.randi_range(stream, from, to)


func randf(stream: String) -> float:
	return _core.randf(stream)


func shuffle(stream: String, array: Array) -> void:
	_core.shuffle(stream, array)
