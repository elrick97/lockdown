class_name DiceTumbler
extends Control
## Presentation seam for the throw-loop Tumble/Reroll phases (dice-tumble spec).
## Owns the visual dice and animates them to faces the RNG already decided — it
## NEVER reads or consumes the RNG. Subclasses (2D sprite / 3D SubViewport)
## override the rendering hooks; this base owns the shared grid layout, timing,
## and lock state so the A/B comparison differs only in rendering.

const COLS := 3
const DIE_SIZE := Vector2(220.0, 220.0)
const DIE_GAP := 40.0

# Shared die-face look (used by renderers to draw/generate pip faces).
const COLOR_FACE := Color(0.92, 0.92, 0.92)
const COLOR_LOCKED := Color(0.35, 0.78, 0.42)
const COLOR_PIP := Color(0.12, 0.12, 0.12)
const PIP := {
	"tl": Vector2(0.28, 0.28), "tc": Vector2(0.5, 0.28), "tr": Vector2(0.72, 0.28),
	"ml": Vector2(0.28, 0.5), "c": Vector2(0.5, 0.5), "mr": Vector2(0.72, 0.5),
	"bl": Vector2(0.28, 0.72), "bc": Vector2(0.5, 0.72), "br": Vector2(0.72, 0.72),
}
const FACE_PIPS := {
	1: ["c"],
	2: ["tl", "br"],
	3: ["tl", "c", "br"],
	4: ["tl", "tr", "bl", "br"],
	5: ["tl", "tr", "c", "bl", "br"],
	6: ["tl", "ml", "bl", "tr", "mr", "br"],
}

var count: int = 0
var faces: Array[int] = []
var locked: Array[bool] = []

var _elapsed := 0.0
var _duration := 1.0
var _active := false


func build(p_count: int) -> void:
	count = p_count
	faces.clear()
	locked.clear()
	for i in count:
		faces.append(1)
		locked.append(false)
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_create_visuals(p_count)


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


func die_rect(index: int) -> Rect2:
	return _die_rect_global(index)


func _settle() -> void:
	for i in count:
		_render_face(i, faces[i], locked[i])


## Local slot rect for die `index` in the centered 3-column grid.
func _slot_rect(index: int) -> Rect2:
	@warning_ignore("integer_division")
	var rows := int(ceil(count / float(COLS)))
	var grid := Vector2(
		COLS * DIE_SIZE.x + (COLS - 1) * DIE_GAP,
		rows * DIE_SIZE.y + (rows - 1) * DIE_GAP
	)
	var origin := (_area() - grid) / 2.0
	var col := index % COLS
	@warning_ignore("integer_division")
	var row := index / COLS
	return Rect2(
		origin + Vector2(col * (DIE_SIZE.x + DIE_GAP), row * (DIE_SIZE.y + DIE_GAP)),
		DIE_SIZE
	)


func _die_rect_global(index: int) -> Rect2:
	var r := _slot_rect(index)
	var p := get_parent()
	if p is Control:
		r.position += (p as Control).global_position
	else:
		r.position += global_position
	return r


# --- overridable rendering hooks ----------------------------------------------

func _create_visuals(_p_count: int) -> void:
	pass


func _render_tumbling(_progress: float) -> void:
	pass


func _render_face(_index: int, _face: int, _is_locked: bool) -> void:
	pass
