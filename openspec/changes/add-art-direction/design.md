## Context

The game renders dice in a 3D SubViewport with an orthographic, straight-down camera (`scripts/viewport_3d_dice_tumbler.gd`), lit by two directional lights. The tray occupies the screen band from 25% to 75% of the height (`throw_scene.gd::_apply_layout`). The renderer is GL Compatibility on desktop and mobile, and textures import as ETC2/ASTC. Style frames must preview what that pipeline can actually draw. A beauty render the game can't reproduce would make the pick meaningless.

## Goals / Non-Goals

**Goals:** three style frames that differ in mood, palette, lighting and shading model, but are all built from the same game-legal asset recipe, so the pick is purely about look. One recipe, three skins.

**Non-goals:** see proposal. No in-game integration and no device measurement. Per the owner's decision of 2026-10-05, all verification is local.

## Decisions

### D1: Shared asset recipe, per-direction skins
One die mesh, one tray mesh, one charm token and one camera rig are shared. Each direction changes only materials, textures, lights and the post overlay. *Alternative:* bespoke models per direction. Rejected because it triples the work and mixes geometry differences into a decision about look.

### D2: Die = beveled cube + 6-tile atlas
The die is a cube with a 2-segment bevel (≈200 tris). Each face's loops are UV-projected onto its dominant axis, landing in one tile of a 3×2 atlas (256 px tiles, 768×512 total). Bevel faces fall on the tile border, which is painted as the material's edge color. Standard layout: +Z=1, −Z=6, +X=3, −X=4, +Y=2, −Y=5 (opposite faces sum to 7). A result is shown by rotating the die. A carved face replaces one tile in a variant atlas. This is also the mesh contract the later integration needs: orient to the result instead of swapping textures (see the proposal's downstream flag).

### D3: Textures are generated, then treated as baked
Albedo (with ambient occlusion around pips and edges painted in), normal (derived from a pip/engraving height map) and roughness are generated per material with numpy inside Blender. The renders read only those image textures, using material features that map 1:1 to Godot `StandardMaterial3D`: albedo, normal, roughness, metallic, emission, alpha, rim/fresnel, and toon diffuse for C. *Alternative:* procedural shader nodes. Rejected because they don't export to glTF/Godot.

### D4: Glass is faked
Glass uses an alpha-blended albedo whose painted inner-thickness gradient fakes depth. It has opaque pips, a fresnel rim (Godot: `rim` plus a small emission) and a strong specular highlight. There is no transmission, refraction, screen-texture read or SSR.

### D5: Frame lighting follows the game's light budget
Each frame uses 1 directional light, at most 2 omni/spot lights, world ambient, and emissive meshes for neon. Neon halos are painted into the tray and table textures, so each frame still reads without real-time glow.

### D6: Post is one overlay, done in numpy
Bloom (threshold plus a blur pyramid), grain, scanlines, vignette and slight chromatic offset are applied to the EEVEE render with numpy. Each is a cheap op that one Godot canvas shader plus optional Compatibility glow can reproduce. Each direction's overlay parameters are recorded in its asset sheet.

### D7: Composition
The camera is orthographic, tilted 18° from top-down so the front faces show. Tilt is a tunable; the current game uses 0°. The frame is 1080×2400, matching PRD §5 bands: HUD (top 15%), tray (middle about 50%), charm row plus throw area (bottom). HUD, buttons and counters are neutral placeholder shapes with no text. The frame shows six dice:
- three Bone (one carved **Wild** face up);
- one Iron;
- two Glass (one mid-tumble with motion blur, one showing a **Spark** carved face on its front side);
- the *Hair Trigger* charm in slot 1 of 5.

Locked dice get a ring marker, because the lock state is part of how the screen reads.

### D8: Readability strip is a companion image
Putting a test strip inside the gameplay frame would spoil the composition. Each direction therefore ships `frame_X_readability.png`. It has three rows: each die type at 126 px (48 dp ≈ 126 px at 1080 px width on a ~411 dp-wide phone), the same row in grayscale, and the same row with tumble motion blur. *This deviates from the proposal's "every frame contains" wording; the content is unchanged.*

### D9: Local Godot check
The dice of each direction export as `.glb` and get imported into the project. `tools/art_preview.gd` renders them in the GL Compatibility renderer on desktop. The same `.glb` is re-imported into Blender under matching neutral light (a round-trip check), and the two renders are stacked in `gltf/preview/*_compare.png`. `tools/art_direction/check_assets.py` checks tri counts and texture sizes against the spec budgets.

### Draft budget tunables (become spec values for the chosen direction)
| Tunable | Value |
|---|---|
| `die_tris_max` | 300 |
| `die_atlas_px` | 768×512 (albedo, normal, roughness/ORM) |
| `tray_tris_max` | 2000 |
| `tray_texture_px` | 1024² albedo, 1024² normal |
| `charm_icon_px` | 256² shipped (authored at 512²) |
| `scene_lights_max` | 1 directional + 2 omni/spot |
| `overlay_passes_max` | 1 canvas shader (+ optional glow) |
| `die_min_px` | 126 (48 dp) |
| `camera_tilt_deg` | 18 (range 0–20) |
| `draw_calls_est_max` | 40 for a full 8-die tray |

## Risks / Trade-offs

- **EEVEE vs Godot shading drift** → mitigated by D3/D9: Godot's render is placed next to Blender's, and drift is noted in the asset sheet.
- **Neon may fight readability.** → The grayscale row in the readability strip catches it, and emissive elements stay outside the dice silhouettes.
- **Toon style C may look cheap at high resolution** → accepted; that's what the comparison is for.
- **Tilted camera changes tap geometry** → it's a tunable, and any change is spec'd later by the integration change, not here.
