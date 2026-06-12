class_name ThrowController
extends RefCounted
## The throw state machine (throw-loop spec). Pure logic: time enters only
## through tick(delta), input only through lock_die(index) — no clocks, no
## frames, no geometry — so the whole loop runs headless under GUT.
##
## Sequence: Draw → Tumble → Lock1 → Reroll → Lock2 → Reroll → Lock3 →
## ForceLock → Resolved. Faces come from the seeded `dice` stream at the start
## of each tumble/re-roll; presentation is strictly downstream.

signal window_started(window_index: int)
signal die_locked(die_index: int, window_index: int)
signal reroll_started(rerolled_indices: Array[int])
signal resolved(result: ThrowResult)

enum State { IDLE, TUMBLE, LOCK_WINDOW, REROLL, RESOLVED }

const WINDOW_COUNT := 3

var state: State = State.IDLE
## 1-based; valid during LOCK_WINDOW (current) and REROLL (the window just ended).
var window_index: int = 0
var faces: Array[int] = []
var locked: Array[bool] = []
var last_result: ThrowResult = null

var _lock_sequence: Array[int] = []
var _window_remaining: Array[float] = [0.0, 0.0, 0.0]
var _accumulated: float = 0.0
var _drawn: Array[StringName] = []
var _config: ThrowConfig
var _bag: DiceBag
var _rng: RngCore


func _init(config: ThrowConfig, bag: DiceBag, rng: RngCore) -> void:
	_config = config
	_bag = bag
	_rng = rng


func start_throw() -> void:
	assert(state == State.IDLE or state == State.RESOLVED, "throw already in progress")
	_drawn = _bag.draw(_config.draw_size, _rng)
	faces.clear()
	locked.clear()
	_lock_sequence.clear()
	_window_remaining = [0.0, 0.0, 0.0]
	for i in _drawn.size():
		faces.append(_roll_face())
		locked.append(false)
	_accumulated = 0.0
	window_index = 0
	state = State.TUMBLE


func tick(delta: float) -> void:
	match state:
		State.TUMBLE, State.REROLL:
			_accumulated += delta
			if _accumulated >= _config.tumble_duration_s:
				_start_window(window_index + 1)
		State.LOCK_WINDOW:
			_accumulated += delta
			if _accumulated >= _config.lock_window_duration_s:
				_end_window_by_expiry()
		_:
			pass


## Locks a die during a lock window. Locks are irreversible within a throw.
## Returns false (and does nothing) outside windows, out of range, or if
## already locked.
func lock_die(index: int) -> bool:
	if state != State.LOCK_WINDOW:
		return false
	if index < 0 or index >= locked.size() or locked[index]:
		return false
	locked[index] = true
	_lock_sequence.append(index)
	die_locked.emit(index, window_index)
	if not locked.has(false):
		_end_window_all_locked()
	return true


## Focus-loss resume rule (PRD §5): the interrupted window restarts from a
## full timer with locks retained. No-op outside a lock window.
func restart_window() -> void:
	if state == State.LOCK_WINDOW:
		_accumulated = 0.0


func time_remaining() -> float:
	if state == State.LOCK_WINDOW:
		return maxf(0.0, _config.lock_window_duration_s - _accumulated)
	return 0.0


func _start_window(index: int) -> void:
	window_index = index
	_accumulated = 0.0
	state = State.LOCK_WINDOW
	window_started.emit(index)


func _end_window_by_expiry() -> void:
	_window_remaining[window_index - 1] = 0.0
	if window_index == WINDOW_COUNT:
		_force_lock_remaining()
		_resolve()
	else:
		_begin_reroll()


func _end_window_all_locked() -> void:
	_window_remaining[window_index - 1] = time_remaining()
	for w in range(window_index + 1, WINDOW_COUNT + 1):
		_window_remaining[w - 1] = _config.lock_window_duration_s
	_resolve()


func _begin_reroll() -> void:
	var rerolled: Array[int] = []
	for i in faces.size():
		if not locked[i]:
			faces[i] = _roll_face()
			rerolled.append(i)
	_accumulated = 0.0
	state = State.REROLL
	reroll_started.emit(rerolled)


func _force_lock_remaining() -> void:
	for i in locked.size():
		if not locked[i]:
			locked[i] = true
			_lock_sequence.append(i)
			die_locked.emit(i, window_index)


func _resolve() -> void:
	state = State.RESOLVED
	_bag.return_dice(_drawn)
	_drawn = []
	var result := ThrowResult.new()
	result.faces = faces.duplicate()
	result.locked_order = _lock_sequence.duplicate()
	result.window_remaining_s = _window_remaining.duplicate()
	last_result = result
	resolved.emit(result)


func _roll_face() -> int:
	return _rng.randi_range(RngCore.STREAM_DICE, 1, 6)
