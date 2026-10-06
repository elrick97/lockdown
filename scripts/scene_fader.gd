extends CanvasLayer
## Scene transitions (run-flow spec, add-scene-transitions). Autoload "SceneFader":
## every screen change goes through change_to(), which covers the screen with a
## smoke wipe, swaps the scene underneath, then reveals the new one. Input is
## blocked while covered. Reduced motion uses a plain fade.

signal covered
signal revealed

const SHADER := preload("res://resources/ui/scene_wipe.gdshader")
## Seconds for each half (cover, reveal).
const TRANSITION_S := 0.22
const PLAIN_S := 0.15

## Tools/tests may set this to swap scenes immediately.
var instant := false
var busy := false
var rect: ColorRect
var _mat: ShaderMaterial


func _ready() -> void:
	layer = 100  # above the Smoke Room overlay (10) and every screen
	process_mode = Node.PROCESS_MODE_ALWAYS
	rect = ColorRect.new()
	rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_mat = ShaderMaterial.new()
	_mat.shader = SHADER
	_mat.set_shader_parameter("noise_tex", SmokeOverlay.noise_texture())
	_mat.set_shader_parameter("progress", 0.0)
	rect.material = _mat
	rect.visible = false
	add_child(rect)


func change_to(path: String) -> void:
	if instant or busy:
		if not busy:
			get_tree().change_scene_to_file(path)
		return
	busy = true
	await cover().finished
	covered.emit()
	get_tree().change_scene_to_file(path)
	await get_tree().process_frame
	await get_tree().process_frame  # the new screen (and its 3D tray) has drawn once
	await reveal().finished
	busy = false
	revealed.emit()


## Smoke rolls in over the screen; taps are blocked until reveal() finishes.
func cover() -> Tween:
	var plain := _reduced_motion()
	_mat.set_shader_parameter("plain", plain)
	rect.visible = true
	rect.mouse_filter = Control.MOUSE_FILTER_STOP
	var t := create_tween()
	t.tween_method(_set_progress, 0.0, 1.0, PLAIN_S if plain else TRANSITION_S)
	return t


func reveal() -> Tween:
	var plain := _reduced_motion()
	var t := create_tween()
	t.tween_method(_set_progress, 1.0, 0.0, PLAIN_S if plain else TRANSITION_S)
	t.tween_callback(func() -> void:
		rect.visible = false
		rect.mouse_filter = Control.MOUSE_FILTER_IGNORE)
	return t


func progress() -> float:
	return float(_mat.get_shader_parameter("progress"))


func _set_progress(v: float) -> void:
	_mat.set_shader_parameter("progress", v)


func _reduced_motion() -> bool:
	var st := get_tree().root.get_node_or_null(^"Settings")
	return st != null and st.reduced_motion
