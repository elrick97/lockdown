## 1. Assets (Blender)

- [x] 1.1 `export_production_dice()`: die.glb, Bone/Iron/Glass atlases (Smoke Room palette) to `res://assets/dice/`
- [x] 1.2 Carve tiles per material × carving (Wild, Gem, Spark), plus `lock_ring.png` and `blob_shadow.png`
- [x] 1.3 Import settings: lossless for atlases and tiles (detect-3D off, mipmaps on the 3D textures); `check_assets.py` covers `assets/dice/` and passes (39 files)

## 2. Data

- [x] 2.1 `DiceMaterial` visual fields; fill `bone/iron/glass.tres`. Added `DiceMaterial.by_id()`: Bone's gameplay id is `standard`, so materials are found by id, not file name (the index keeps paths only, so no textures outlive the renderer at exit)
- [x] 2.2 `DieAtlasCache` stamping + tests (face-6 tile replaced, other tiles unchanged, cache reuse, stamp rects checked against the mesh's real UVs). Carve tiles are found beside the material's atlas (`bone_albedo.png` → `bone_wild_*`)

## 3. Renderer

- [x] 3.1 Orientation math `face_up_basis` + tests (every face lands up and upright within 1°, deterministic, no RNG use)
- [x] 3.2 Mesh dice + per-die materials from `DiceMaterial` (Glass transparency, rim, faint glow). Deviation: Glass relies on Godot's built-in back-to-front sort of transparent objects; no flicker was seen, so the manual render-priority pass was not added
- [x] 3.3 Tilted ortho camera, projected `die_rect`; 2D slot grid removed. Deviation: the SubViewport renders at full tray resolution with 2× MSAA instead of 0.6 scale, so dice stay crisp at tap size (frame time below shows the cost is negligible)
- [x] 3.4 Ring, blob shadow, dead dim, amber flash; `throw_scene` passes drawn dice to `build()`
- [x] 3.5 Tests: tap rects ≥ 126 px and non-overlapping for 8 dice; center tap locks that die (event-position test)

## 4. Spec cleanup and verification

- [x] 4.1 Full GUT suite green (177)
- [x] 4.2 Desktop playthrough green (0 failed checks) with screenshots of all materials, carvings, locked ring and dead slots. Fixed on the way: the harness added Bone dice as `bone` (the game uses `standard`), and the Iron timing check is now frame-independent
- [x] 4.3 `tools/perf_dice.gd`, desktop stand-in (RTX 5060 laptop, GL Compatibility, internal 1080×2400, 8 dice re-tumbling 20 s, vsync off): average 0.63 ms, 95th percentile 1.38 ms, worst 4.19 ms
