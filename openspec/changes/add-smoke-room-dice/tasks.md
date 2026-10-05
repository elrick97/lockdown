## 1. Assets (Blender)

- [ ] 1.1 `export_production_dice()`: die.glb, Bone/Iron/Glass atlases (Smoke Room palette) to `res://assets/dice/`
- [ ] 1.2 Carve tiles per material × carving (Wild, Gem, Spark), plus `lock_ring.png` and `blob_shadow.png`
- [ ] 1.3 Import settings: lossless for atlases and tiles; `check_assets.py` covers `assets/dice/` and passes

## 2. Data

- [ ] 2.1 `DiceMaterial` visual fields; fill `bone/iron/glass.tres`
- [ ] 2.2 `DieAtlasCache` stamping + tests (face-6 tile replaced, other tiles unchanged, cache reuse)

## 3. Renderer

- [ ] 3.1 Orientation math `face_up_basis` + tests (every face lands up within 1°, deterministic, no RNG use)
- [ ] 3.2 Mesh dice + per-die materials from `DiceMaterial` (Glass transparency, rim, render priority)
- [ ] 3.3 Tilted ortho camera, viewport aspect/scale, projected `die_rect`; remove 2D slot grid
- [ ] 3.4 Ring, blob shadow, dead dim, amber flash; `throw_scene` passes drawn dice to `build()`
- [ ] 3.5 Tests: tap rects ≥ 126 px and non-overlapping for 8 dice; center tap locks that die

## 4. Spec cleanup and verification

- [ ] 4.1 Full GUT suite green
- [ ] 4.2 Desktop playthrough green, plus screenshot checks of the new dice (all materials, a carving, locked ring, dead slot)
- [ ] 4.3 `tools/perf_dice.gd`: desktop frame time with 8 dice tumbling, reported as a stand-in
