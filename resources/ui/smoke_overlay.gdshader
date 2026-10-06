// Smoke Room film overlay (art-direction spec: grain 0.07, vignette 0.6, no scanlines,
// no chroma). One full-screen pass; grain steps at a fixed 24 per second.
shader_type canvas_item;

uniform float grain : hint_range(0.0, 0.3) = 0.07;
uniform float vignette : hint_range(0.0, 1.0) = 0.6;
uniform float grain_fps = 24.0;

// Integer hash (no visible structure, unlike the sin() hash at large pixel coordinates).
float hash(uvec2 p, uint frame) {
	uint h = p.x * 1597334677u ^ p.y * 3812015801u ^ frame * 2654435761u;
	h = (h ^ (h >> 16u)) * 2246822519u;
	h ^= h >> 13u;
	return float(h & 65535u) / 65535.0;
}

void fragment() {
	uint frame = uint(floor(TIME * grain_fps));
	float n = hash(uvec2(FRAGCOORD.xy), frame) - 0.5;
	vec2 c = UV - 0.5;
	float d = length(c) / 0.7071;  // 0 at the centre, 1 in the corners
	// Corner-weighted: the HUD (top centre, d ≈ 0.7) stays readable; the lamp pool's
	// falloff is already painted into the backdrop and felt.
	float vig = vignette * smoothstep(0.55, 1.05, d);
	// Darken toward the edges; grain adds +/- light noise over the whole frame.
	COLOR = vec4(vec3(n > 0.0 ? 1.0 : 0.0), abs(n) * grain * 2.0);
	COLOR = mix(COLOR, vec4(0.0, 0.0, 0.0, 1.0), vig);
}
