class_name SpriteDiceTumbler
extends DiceTumbler
## Spike A: 2D dice drawn procedurally (pips), animating to rest via a
## slot-machine scramble + settle bounce over the tumble duration. No binary
## assets, no RNG — purely a presentation of faces already decided.

const COLOR_UNLOCKED := Color(0.92, 0.92, 0.92)
const COLOR_LOCKED := Color(0.35, 0.78, 0.42)
const COLOR_PIP := Color(0.12, 0.12, 0.12)
const COLOR_BORDER := Color(0.6, 0.6, 0.6)
const SCRAMBLE_UNTIL := 0.82  # fraction of duration spent scrambling before locking in

# Normalized pip positions within a die face.
const _PIP := {
	"tl": Vector2(0.28, 0.28), "tc": Vector2(0.5, 0.28), "tr": Vector2(0.72, 0.28),
	"ml": Vector2(0.28, 0.5), "c": Vector2(0.5, 0.5), "mr": Vector2(0.72, 0.5),
	"bl": Vector2(0.28, 0.72), "bc": Vector2(0.5, 0.72), "br": Vector2(0.72, 0.72),
}
const _FACE_PIPS := {
	1: ["c"],
	2: ["tl", "br"],
	3: ["tl", "c", "br"],
	4: ["tl", "tr", "bl", "br"],
	5: ["tl", "tr", "c", "bl", "br"],
	6: ["tl", "ml", "bl", "tr", "mr", "br"],
}

var _shown: Array[int] = []
var _bounce: Array[float] = []
var _scramble_frame := 0


func _create_visuals(p_count: int) -> void:
	_shown.clear()
	_bounce.clear()
	for i in p_count:
		_shown.append(1)
		_bounce.append(0.0)
	queue_redraw()


func _render_tumbling(progress: float) -> void:
	_scramble_frame += 1
	for i in count:
		if locked[i]:
			_bounce[i] = 0.0
			continue
		if progress < SCRAMBLE_UNTIL:
			# Visual cycle only (never the gameplay RNG, PRD §6).
			_shown[i] = 1 + (_scramble_frame / 2 + i) % 6
			_bounce[i] = -absf(sin(progress * PI * 5.0)) * 36.0 * (1.0 - progress)
		else:
			_shown[i] = faces[i]
			# Settle bounce easing out over the final stretch.
			var t := (progress - SCRAMBLE_UNTIL) / (1.0 - SCRAMBLE_UNTIL)
			_bounce[i] = -absf(sin(t * PI * 2.0)) * 18.0 * (1.0 - t)
	queue_redraw()


func _render_face(index: int, face: int, _is_locked: bool) -> void:
	if index >= 0 and index < _shown.size():
		_shown[index] = face
		_bounce[index] = 0.0
	queue_redraw()


@warning_ignore("integer_division")
func _draw() -> void:
	for i in count:
		var rect := _slot_rect(i)
		rect.position.y += _bounce[i] if i < _bounce.size() else 0.0
		var bg := COLOR_LOCKED if locked[i] else COLOR_UNLOCKED
		draw_rect(rect, bg, true)
		draw_rect(rect, COLOR_BORDER, false, 3.0)
		_draw_pips(rect, _shown[i] if i < _shown.size() else faces[i])


func _draw_pips(rect: Rect2, face: int) -> void:
	var pips: Array = _FACE_PIPS.get(clampi(face, 1, 6), [])
	var radius := rect.size.x * 0.075
	for key in pips:
		var n: Vector2 = _PIP[key]
		var center := rect.position + Vector2(n.x * rect.size.x, n.y * rect.size.y)
		draw_circle(center, radius, COLOR_PIP)
