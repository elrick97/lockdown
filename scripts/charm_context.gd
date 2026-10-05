class_name CharmContext
extends RefCounted
## Immutable snapshot of game state passed to every charm hook (charm-effect
## spec). Arrays are defensive copies; charms must not mutate them.

## Faces of all locked dice (in lock order).
var locked_faces: Array[int] = []
## Which window each tray die was locked in (indexed by die slot; 0 = not yet locked).
var locked_windows: Array[int] = []
## Remaining seconds per window at the time of hook dispatch.
var window_times: Array[float] = []
## 0 for on_score (post-resolve); 1–3 for on_window/on_lock.
var current_window: int = 0
## Die slot being locked; -1 for on_throw/on_window/on_score.
var die_index: int = -1
var round_total: int = 0
var throw_number: int = 0


## Build a context for on_score from a resolved ThrowResult.
static func from_result(result: ThrowResult) -> CharmContext:
	var ctx := CharmContext.new()
	for idx in result.locked_order:
		ctx.locked_faces.append(result.faces[idx])
	ctx.locked_windows.resize(result.faces.size())
	ctx.locked_windows.fill(0)
	for seq_i in result.locked_order.size():
		var die_idx: int = result.locked_order[seq_i]
		var win: int = result.lock_windows[seq_i] if seq_i < result.lock_windows.size() else 0
		ctx.locked_windows[die_idx] = win
	ctx.window_times = result.window_remaining_s.duplicate()
	ctx.current_window = 0
	ctx.die_index = -1
	return ctx


## Build a context for on_throw (pre-window; all dice just rolled).
static func for_throw(faces: Array[int], locked: Array[bool]) -> CharmContext:
	var ctx := CharmContext.new()
	ctx.locked_windows.resize(faces.size())
	ctx.locked_windows.fill(0)
	for i in faces.size():
		if locked[i]:
			ctx.locked_faces.append(faces[i])
	ctx.current_window = 0
	ctx.die_index = -1
	return ctx


## Build a context for on_window.
static func for_window(window_idx: int, faces: Array[int], locked: Array[bool],
		lock_wins: Array[int], window_remaining: Array[float]) -> CharmContext:
	var ctx := CharmContext.new()
	ctx.locked_windows = lock_wins.duplicate()
	for i in faces.size():
		if locked[i]:
			ctx.locked_faces.append(faces[i])
	ctx.window_times = window_remaining.duplicate()
	ctx.current_window = window_idx
	ctx.die_index = -1
	return ctx


## Build a context for on_lock.
static func for_lock(die_idx: int, window_idx: int, faces: Array[int],
		locked: Array[bool], lock_wins: Array[int]) -> CharmContext:
	var ctx := CharmContext.new()
	ctx.locked_windows = lock_wins.duplicate()
	for i in faces.size():
		if locked[i]:
			ctx.locked_faces.append(faces[i])
	ctx.current_window = window_idx
	ctx.die_index = die_idx
	return ctx
