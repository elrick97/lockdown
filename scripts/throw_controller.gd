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
signal carve_activated(die_index: int, carve_type: StringName)
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
## Window (1-3) in which each entry of _lock_sequence was locked. Parallel array.
var _lock_windows: Array[int] = []
var _window_remaining: Array[float] = [0.0, 0.0, 0.0]
var _accumulated: float = 0.0
var _drawn: Array[DiceBag.Die] = []
var _shattered: Array[bool] = []
var _material_cache: Dictionary = {}
var _config: ThrowConfig
var _bag: DiceBag
var _rng: RngCore
var _inventory: CharmInventory = null


func _init(config: ThrowConfig, bag: DiceBag, rng: RngCore,
		inventory: CharmInventory = null) -> void:
	_config = config
	_bag = bag
	_rng = rng
	_inventory = inventory


func start_throw() -> void:
	assert(state == State.IDLE or state == State.RESOLVED, "throw already in progress")
	_drawn = _bag.draw(_config.draw_size, _rng)
	faces.clear()
	locked.clear()
	_lock_sequence.clear()
	_lock_windows.clear()
	_shattered.clear()
	_window_remaining = [0.0, 0.0, 0.0]
	for i in _drawn.size():
		faces.append(_roll_face())
		locked.append(false)
		_shattered.append(false)
	_accumulated = 0.0
	window_index = 0
	state = State.TUMBLE
	if _inventory != null:
		var ctx := CharmContext.for_throw(faces, locked)
		for charm in _inventory.iter_charms():
			charm.on_throw(ctx)


func tick(delta: float) -> void:
	match state:
		State.TUMBLE, State.REROLL:
			_accumulated += delta
			if _accumulated >= tumble_duration():
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
	if index < 0 or index >= locked.size() or locked[index] or _shattered[index]:
		return false  # shattered Glass is a dead slot (dice-materials spec)
	locked[index] = true
	_lock_sequence.append(index)
	_lock_windows.append(window_index)
	die_locked.emit(index, window_index)
	if index < _drawn.size():
		var _d := _drawn[index]
		if _d.carved_face == faces[index] and _d.carve_type != &"":
			carve_activated.emit(index, _d.carve_type)
	if _inventory != null:
		var ctx := CharmContext.for_lock(index, window_index, faces, locked, _lock_wins_by_slot())
		for charm in _inventory.iter_charms():
			charm.on_lock(index, faces[index], window_index, ctx)
	if _all_done():
		_end_window_all_locked()
	return true


## Focus-loss resume rule (PRD §5): the interrupted window restarts from a
## full timer with locks retained. No-op outside a lock window.
func restart_window() -> void:
	if state == State.LOCK_WINDOW:
		_accumulated = 0.0


## Every slot is done: locked, or a dead slot that can never be locked.
func _all_done() -> bool:
	for i in locked.size():
		if not locked[i] and not _shattered[i]:
			return false
	return true


## True when the die in `index` is a dead slot (Glass shattered on re-roll).
func is_shattered(index: int) -> bool:
	return index >= 0 and index < _shattered.size() and _shattered[index]


func time_remaining() -> float:
	if state == State.LOCK_WINDOW:
		return maxf(0.0, _config.lock_window_duration_s - _accumulated)
	return 0.0


func _start_window(index: int) -> void:
	window_index = index
	_accumulated = 0.0
	state = State.LOCK_WINDOW
	window_started.emit(index)
	if _inventory != null:
		var ctx := CharmContext.for_window(index, faces, locked, _lock_wins_by_slot(), _window_remaining)
		for charm in _inventory.iter_charms():
			charm.on_window(index, ctx)


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
		if locked[i] or _shattered[i]:
			continue
		var mat := _material_res(_drawn[i].material_id)
		if mat != null and mat.shatter_on_reroll:
			_shattered[i] = true
		else:
			faces[i] = _roll_face()
			rerolled.append(i)
	if _all_done():
		# Nothing left to lock: resolve now instead of running empty windows. The
		# skipped windows keep their 0 s (no credit: nothing was locked in them).
		_resolve()
		return
	_accumulated = 0.0
	state = State.REROLL
	reroll_started.emit(rerolled)


func _force_lock_remaining() -> void:
	for i in locked.size():
		if locked[i] or _shattered[i]:
			continue
		locked[i] = true
		_lock_sequence.append(i)
		_lock_windows.append(window_index)
		die_locked.emit(i, window_index)
		if i < _drawn.size():
			var _d := _drawn[i]
			if _d.carved_face == faces[i] and _d.carve_type != &"":
				carve_activated.emit(i, _d.carve_type)
		if _inventory != null:
			var ctx := CharmContext.for_lock(i, window_index, faces, locked, _lock_wins_by_slot())
			for charm in _inventory.iter_charms():
				charm.on_lock(i, faces[i], window_index, ctx)


func _resolve() -> void:
	state = State.RESOLVED
	var result := ThrowResult.new()
	result.faces = faces.duplicate()
	result.locked_order = _lock_sequence.duplicate()
	result.lock_windows = _lock_windows.duplicate()
	result.window_remaining_s = _window_remaining.duplicate()
	result.shattered = _shattered.duplicate()
	var pip_off: Array[int] = []
	var pip_mul: Array[int] = []
	var carve_types: Array[StringName] = []
	for i in faces.size():
		var die_mat: StringName = _drawn[i].material_id if i < _drawn.size() else &"standard"
		var mat := _material_res(die_mat)
		pip_off.append(mat.pip_offset if mat != null else 0)
		pip_mul.append(mat.pip_multiplier if mat != null else 1)
		if i < _drawn.size():
			var _d := _drawn[i]
			carve_types.append(_d.carve_type if _d.carved_face == faces[i] else &"")
		else:
			carve_types.append(&"")
	result.pip_offsets = pip_off
	result.pip_multipliers = pip_mul
	result.carve_types = carve_types
	_bag.return_dice(_drawn)
	_drawn = []
	last_result = result
	resolved.emit(result)


func _roll_face() -> int:
	return _rng.randi_range(RngCore.STREAM_DICE, 1, 6)


## Slot-indexed array: slot → window it was locked in (0 = not yet locked).
func _lock_wins_by_slot() -> Array[int]:
	var arr: Array[int] = []
	arr.resize(faces.size())
	arr.fill(0)
	for i in _lock_sequence.size():
		arr[_lock_sequence[i]] = _lock_windows[i]
	return arr


## Trinket: Re-Tumble — re-rolls all currently unlocked, non-shattered dice
## without changing state. Only callable during LOCK_WINDOW.
func force_reroll_unlocked() -> void:
	if state != State.LOCK_WINDOW:
		return
	var rerolled: Array[int] = []
	for i in faces.size():
		if not locked[i] and not _shattered[i]:
			faces[i] = _roll_face()
			rerolled.append(i)
	if not rerolled.is_empty():
		reroll_started.emit(rerolled)


## Trinket: Freeze Timer — extends the current window by subtracting duration
## from _accumulated. Only callable during LOCK_WINDOW.
func freeze_window(duration: float) -> void:
	if state != State.LOCK_WINDOW:
		return
	_accumulated = maxf(0.0, _accumulated - duration)


## Tumble/re-roll duration for this throw: base × the slowest drawn material's
## tumble_duration_factor (dice-materials spec: Iron 1.4). The scene animates with
## this same value, so the window never opens while dice are still tumbling.
func tumble_duration() -> float:
	var factor := 1.0
	for d in _drawn:
		var mat := _material_res(d.material_id)
		if mat != null:
			factor = maxf(factor, mat.tumble_duration_factor)
	return _config.tumble_duration_s * factor


func _material_res(name: StringName) -> DiceMaterial:
	if _material_cache.has(name):
		return _material_cache[name] as DiceMaterial
	var path := "res://resources/dice_materials/%s.tres" % name
	if ResourceLoader.exists(path):
		var res := load(path) as DiceMaterial
		_material_cache[name] = res
		return res
	_material_cache[name] = null
	return null
