## Context

The dice SubViewport is transparent over the tray Control. Screens are built in code with the shared theme. The Blender script already has felt and backdrop generators for the style frames (`make_tray`, `make_table`), but they feed 3D materials.

## Decisions

### D1: Flat 2D textures with the light painted in
`export_production_table()` reuses the noise and SDF helpers to paint:
- **`felt.png`:** felt fibres and mottling, a lamp pool (centre ×1.32, base ×0.42, radius 3.0 in tray units, per the spec), wall AO, a dark leather rim band with a thin brass line.
- **`backdrop.png`:** walnut planks with a radial falloff centred on the tray band (screen y ≈ 46%).

They're drawn with `TextureRect` (stretch scale), so the game needs no 3D table geometry and no real-time light.

### D2: Lossy WebP import
Smaller download for the web build (one copy, ≈ 10× smaller than lossless). VRAM use (≈ 12 MB uncompressed RGBA) is fine.

### D3: `SmokeOverlay` (CanvasLayer, layer 10)
A full-rect `ColorRect` with a canvas shader: grain from a hash of the pixel coordinate and `floor(TIME × 24)`, scaled by 0.07 and weighted toward midtones; vignette `1 − 0.6 × smoothstep(0.55, 1.05, distance)`, weighted to the corners so the top-centre HUD keeps its contrast (ui-theme spec); the pool's falloff is already painted into the textures. The grain uses an integer hash: the usual `sin()` hash showed diagonal hatching at full resolution. `mouse_filter = IGNORE`. Each screen adds it in `_ready` with `SmokeOverlay.add_to(self)`.

### D4: Placement per screen
- **Throw:** backdrop at child index 0; felt as the tray's first child, behind the tumbler.
- **Shop:** backdrop at index 0.
- **Start:** the backdrop replaces the flat background colour.
- **All screens:** the overlay is on top.

## Risks / Trade-offs

- **Felt stretched to the tray band's 1080 × 936 aspect** (≈ 15%). Acceptable for noisy felt; the pool stays round enough.
