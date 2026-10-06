// Smoke Room overlay (art-direction spec): slow drifting fog that hangs at the screen
// edges and rises from the bottom, plus the corner vignette. No per-frame noise: the
// fog moves continuously and slowly, so nothing flickers. One full-screen pass, four
// samples of a small seamless noise texture (cheap on GL Compatibility mobile).
shader_type canvas_item;

uniform sampler2D noise_tex : repeat_enable, filter_linear;
uniform float vignette : hint_range(0.0, 1.0) = 0.6;
uniform vec3 fog_color : source_color = vec3(0.68, 0.6, 0.52);
uniform float fog_edge : hint_range(0.0, 1.0) = 0.62;    // density at the screen edges
uniform float fog_center : hint_range(0.0, 1.0) = 0.04; // density over the play area
uniform float fog_drift = 0.015;                          // screen heights per second

void fragment() {
	vec2 screen = 1.0 / SCREEN_PIXEL_SIZE;
	vec2 p = UV * vec2(1.0, screen.y / screen.x);  // square units: x 0..1, y 0..~2.2
	float t = TIME * fog_drift;
	// Domain warp: two slow, cross-moving samples bend the main sample into curls.
	float wx = texture(noise_tex, p * 0.45 + vec2(t * 0.7, t * 0.4)).r - 0.5;
	float wy = texture(noise_tex, p * 0.45 + vec2(0.37, 0.71) - vec2(t * 0.5, t * 0.9)).r - 0.5;
	vec2 q = p * 0.5 + vec2(wx, wy) * 0.6 + vec2(-t * 0.6, t * 2.2);  // drifts upward
	float n = texture(noise_tex, q).r;
	float n2 = texture(noise_tex, q * 1.7 + vec2(t * 1.7, t * 0.8)).r;
	// Soft body: a base haze plus broad, low-contrast billows (no hard veins).
	float smoke = 0.22 + 0.78 * smoothstep(0.3, 0.8, n * 0.75 + n2 * 0.25);

	// Where the fog lives: the side margins, heavy at the bottom, light over the HUD,
	// thicker in the corners; only a faint haze over the play area.
	vec2 c = UV - 0.5;
	float sides = smoothstep(0.33, 0.5, abs(c.x));
	float bottom = smoothstep(0.26, 0.5, c.y);
	float top = smoothstep(0.42, 0.5, -c.y) * 0.55;
	float d = length(c) / 0.7071;
	float corners = smoothstep(0.6, 1.0, d);
	float edge = clamp(max(max(sides, bottom), max(top, corners)), 0.0, 1.0);
	float a = mix(fog_center, fog_edge, edge) * smoke;
	vec3 col = fog_color * (0.82 + 0.3 * n2);

	// Composite fog, then darken toward the corners (vignette).
	float vig = vignette * smoothstep(0.55, 1.05, d);
	float alpha = a * (1.0 - vig) + vig;
	vec3 rgb = alpha > 0.0001 ? col * a * (1.0 - vig) / alpha : vec3(0.0);
	COLOR = vec4(rgb, alpha);
}
