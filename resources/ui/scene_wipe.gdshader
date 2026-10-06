// Scene transition (run-flow spec, add-scene-transitions): dark warm smoke dissolves
// across the screen as `progress` goes 0 → 1, using the same fog noise as the
// Smoke Room overlay. `plain` = reduced motion: an even fade to dark.
shader_type canvas_item;

uniform sampler2D noise_tex : repeat_enable, filter_linear;
uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform bool plain = false;
uniform vec3 smoke_color : source_color = vec3(0.07, 0.042, 0.03);

void fragment() {
	vec2 screen = 1.0 / SCREEN_PIXEL_SIZE;
	vec2 p = UV * vec2(1.0, screen.y / screen.x);
	float n = texture(noise_tex, p * 0.8).r * 0.7 + texture(noise_tex, p * 2.1 + vec2(0.31, 0.17)).r * 0.3;
	float a;
	if (plain) {
		a = progress;
	} else {
		float edge = progress * 1.4 - 0.2;
		a = 1.0 - smoothstep(edge - 0.12, edge + 0.12, n);
	}
	COLOR = vec4(smoke_color * (0.75 + 0.5 * n), clamp(a, 0.0, 1.0));
}
