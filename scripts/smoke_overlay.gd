class_name SmokeOverlay
extends CanvasLayer
## Full-screen film grain + vignette over a screen (art-direction spec, Smoke Room).
## Never intercepts input. Add it from a screen's _ready with SmokeOverlay.add_to(self).

const SHADER := preload("res://resources/ui/smoke_overlay.gdshader")
const BACKDROP := preload("res://assets/table/backdrop.png")

var rect: ColorRect


static func add_to(screen: Node) -> SmokeOverlay:
	var overlay := SmokeOverlay.new()
	overlay.layer = 10
	overlay.rect = ColorRect.new()
	overlay.rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var mat := ShaderMaterial.new()
	mat.shader = SHADER
	overlay.rect.material = mat
	overlay.add_child(overlay.rect)
	screen.add_child(overlay)
	return overlay


## Full-screen dark walnut backdrop with the lamp pool's falloff, behind everything.
static func add_backdrop(screen: Control) -> TextureRect:
	var bg := TextureRect.new()
	bg.texture = BACKDROP
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_SCALE
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	screen.add_child(bg)
	screen.move_child(bg, 0)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	return bg
