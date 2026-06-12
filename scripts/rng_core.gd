class_name RngCore
extends RefCounted
## The single source of gameplay randomness (PRD §6: determinism law).
##
## One run seed derives independent named streams, so consuming randomness
## in one domain (e.g. shop re-rolls) never shifts outcomes in another
## (e.g. die faces). Plain RefCounted so tests run headless without the
## scene tree; the RngService autoload is a thin facade over this class.

const STREAM_DICE := "dice"
const STREAM_SHOP := "shop"
const STREAM_BAG := "bag"

var run_seed: int
var _streams: Dictionary = {}


func _init(seed_value: int = 0) -> void:
	if seed_value == 0:
		var boot := RandomNumberGenerator.new()
		boot.randomize()
		seed_value = boot.randi()
		if seed_value == 0:
			seed_value = 1
	run_seed = seed_value


func randi_range(stream: String, from: int, to: int) -> int:
	return _stream(stream).randi_range(from, to)


func randf(stream: String) -> float:
	return _stream(stream).randf()


func shuffle(stream: String, array: Array) -> void:
	# Fisher-Yates; Array.shuffle() would use the global RNG and break determinism.
	var rng := _stream(stream)
	for i in range(array.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp: Variant = array[i]
		array[i] = array[j]
		array[j] = tmp


func _stream(stream_name: String) -> RandomNumberGenerator:
	if not _streams.has(stream_name):
		var rng := RandomNumberGenerator.new()
		# String hash is platform-independent, so derived seeds reproduce everywhere.
		rng.seed = hash("%d:%s" % [run_seed, stream_name])
		_streams[stream_name] = rng
	return _streams[stream_name]
