class_name DiceTumbler
extends Control
## Presentation seam for the throw-loop Tumble/Reroll phases (dice-tumble spec).
## Owns the visual dice and animates them to faces the RNG already decided — it
## NEVER reads or consumes the RNG. This base owns timing and the per-die state
## (faces, locked, dead); the concrete renderer draws the dice and reports where
## each one is on screen (die_rect) so taps resolve against what is drawn.

var count: int = 0
var faces: Array[int] = []
var locked: Array[bool] = []
var dead: Array[bool] = []  # dead slots keep their last face and never animate
## Drawn dice for this throw (material + carving per slot), for the renderer's look.
var dice: Array[DiceBag.Die] = []

var _elapsed := 0.0
var _duration := 1.0
var _active := false


func build(p_dice: Array[DiceBag.Die]) -> void:
	dice = p_dice.duplicate()
	count = dice.size()
	faces.clear()
	locked.clear()
	dead.clear()
	for i in count:
		faces.append(1)
		locked.append(false)
		dead.append(false)
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_create_visuals(count)


## The drawable area is the parent tray's size, read live — relying on this
## node's own `size` is unreliable until anchors settle (Android init quirk).
func _area() -> Vector2:
	var p := get_parent()
	if p is Control:
		return (p as Control).size
	return size


## Begin animating unlocked dice toward their predetermined faces. Locked dice
## keep their faces and do not animate (dice-tumble spec).
func begin_tumble(p_faces: Array[int], p_locked: Array[bool], duration: float) -> void:
	faces = p_faces.duplicate()
	locked = p_locked.duplicate()
	_duration = maxf(duration, 0.0001)
	_elapsed = 0.0
	_active = true


func tick(delta: float) -> void:
	if not _active:
		return
	_elapsed += delta
	var progress := clampf(_elapsed / _duration, 0.0, 1.0)
	_render_tumbling(progress)
	if progress >= 1.0:
		_active = false
		_settle()


func is_settled() -> bool:
	return not _active


## Force every die to show its final face (called when the lock window opens, so
## the displayed faces are guaranteed correct regardless of animation progress).
func reveal(p_faces: Array[int], p_locked: Array[bool]) -> void:
	faces = p_faces.duplicate()
	locked = p_locked.duplicate()
	_active = false
	_settle()


func lock_die(index: int, face: int) -> void:
	if index >= 0 and index < locked.size():
		locked[index] = true
		faces[index] = face
		_render_face(index, face, true)


## Dead slot (dice-materials spec): the die keeps its last face visually, is drawn
## dimmed, and is skipped by every later tumble.
func mark_dead(index: int) -> void:
	if index >= 0 and index < dead.size():
		dead[index] = true
		_render_face(index, faces[index], false)


func is_static(index: int) -> bool:
	return locked[index] or (index < dead.size() and dead[index])


func _settle() -> void:
	for i in count:
		_render_face(i, faces[i], locked[i])


# --- renderer hooks -------------------------------------------------------------

## Screen-space (global canvas) bounds of die `index` as drawn; taps resolve
## against this (dice-tumble spec). Renderers must override it.
func die_rect(_index: int) -> Rect2:
	return Rect2()


func _create_visuals(_p_count: int) -> void:
	pass


func _render_tumbling(_progress: float) -> void:
	pass


func _render_face(_index: int, _face: int, _is_locked: bool) -> void:
	pass


## Flash die `index` to `color` and back to its resting look over `duration` s.
func flash_die(_index: int, _color: Color, _duration: float) -> void:
	pass


## Scale die `index` up to `amount` and back over `duration` s (lock / score punch).
func punch_die(_index: int, _amount: float, _duration: float) -> void:
	pass
