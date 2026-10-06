class_name SmokeOverlay
extends CanvasLayer
## Full-screen drifting fog + vignette over a screen (art-direction spec, Smoke Room).
## Never intercepts input. Add it from a screen's _ready with SmokeOverlay.add_to(self).

const SHADER := preload("res://resources/ui/smoke_overlay.gdshader")
const BACKDROP := preload("res://assets/table/backdrop.png")
const NOISE_PX := 256

var rect: ColorRect

## One seamless fractal-noise texture shared by every screen's overlay.
static var _noise: NoiseTexture2D


static func noise_texture() -> NoiseTexture2D:
	if _noise == null:
		var n := FastNoiseLite.new()
		n.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
		n.fractal_type = FastNoiseLite.FRACTAL_FBM
		n.fractal_octaves = 4
		n.frequency = 0.008
		n.seed = 7  # fixed: the fog is decoration, never run randomness
		_noise = NoiseTexture2D.new()
		_noise.width = NOISE_PX
		_noise.height = NOISE_PX
		_noise.seamless = true
		_noise.noise = n
	return _noise


static func add_to(screen: Node) -> SmokeOverlay:
	var overlay := SmokeOverlay.new()
	overlay.layer = 10
	overlay.rect = ColorRect.new()
	overlay.rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var mat := ShaderMaterial.new()
	mat.shader = SHADER
	mat.set_shader_parameter("noise_tex", noise_texture())
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
