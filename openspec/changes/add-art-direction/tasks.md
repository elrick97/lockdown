## 1. Setup

- [x] 1.1 Add git-lfs rules for `assets/art_direction/**/*.blend`, `*.glb` and `assets/art_direction/**/*.png`; create `/assets/art_direction/{source,gltf,textures}`

## 2. Shared asset recipe (Blender)

- [x] 2.1 Die mesh: beveled cube ≤300 tris, six-face atlas UVs (D2)
- [x] 2.2 Atlas generator: albedo/normal/roughness per material, carved tiles Wild/Gem/Spark (D3)
- [x] 2.3 Tray mesh ≤2000 tris, table plane, charm token, neon pictogram tubes
- [x] 2.4 Camera rig: ortho 18° tilt, 1080×2400, layout bands, HUD/button placeholders (D7)
- [x] 2.5 Post overlay in numpy: bloom, grain, scanlines, vignette, chromatic offset (D6)

## 3. Style frames

- [x] 3.1 Frame A, Felt & Neon: materials, lights, render, post → `frame_a_felt_neon.png`
- [x] 3.2 Frame B, Smoke Room → `frame_b_smoke_room.png`
- [x] 3.3 Frame C, Arcade Cabinet → `frame_c_arcade.png`
- [x] 3.4 Readability strip per frame (D8) and charm icon per frame (256² + 512² source)
- [x] 3.5 Asset sheet per frame: palette hexes, tri counts, texture sizes, lights, overlay params, draw-call estimate

## 4. Local verification

- [x] 4.1 Export each direction's dice to `.glb`; verify tri counts and texture dimensions with a script
- [x] 4.2 `tools/art_preview.gd`: render the `.glb` dice in Godot GL Compatibility on desktop and save a side-by-side PNG (`gltf/preview/*_compare.png`, Godot top / Blender round-trip bottom)
- [x] 4.3 Comparison sheet of all three frames (`comparison.png`) → owner picked **B, Smoke Room**

## 5. Decision

- [x] 5.1 Log the pick in PRD §5 (like §10.1); fill the chosen palette, lighting and overlay into the `art-direction` spec
