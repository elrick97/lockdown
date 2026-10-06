## Why

The art direction is decided (Smoke Room, `art-direction` spec), but the game still draws gray-box dice: six identical quads that all show the same face texture, tinted green when locked. That can't carry the chosen look. A Smoke Room die is a real six-faced die on one atlas, so the tumble must turn it to land on its result instead of swapping textures. Dice are what the player reads under time pressure, so they come first. This is the dice half of TASKS.md M1 "Placeholder → first-pass dice/charm art for slice content". Charm icons, the table and the UI theme are separate changes. PRD trace: §5 (art direction, readability at speed), §4.2/§4.3 (materials, carved faces), §10.1 (3D SubViewport tumble).

**Pillars served:** *Readable depth*: Bone, Iron and Glass and the carved faces read at a glance, mid-tumble and at tap size. *Jackpot payoff*: real dice tumbling to rest is the spectacle the 3D spike was chosen for. *Collect & unlock*: bought materials and carvings look like what they are.

## What Changes

- **Six-face Smoke Room dice.** The Blender recipe's die (188 tris, one 768×512 atlas in the standard face layout) replaces the quad cube, with Smoke Room textures for Bone, Iron and Glass. Glass is faked per the spec (alpha, fresnel rim, no refraction).
- **Tumble lands on the result by rotation.** Each die animates to the orientation that puts its predetermined face up, plus a small yaw. The yaw comes from the slot index, never the RNG. Faces are still fixed before motion (dice-tumble law unchanged); only the presentation changes.
- **Camera: orthographic, 18° tilt** (owner decision; `camera_tilt_deg` tunable in the art-direction spec), so front faces and carvings on the sides read.
- **Taps follow the dice you see.** Tap rectangles come from each die's projected on-screen position, not a fixed 2D grid, so the tilt can't make taps miss. Each die stays at or above 126 px (48 dp).
- **Materials carry their visuals as data.** `DiceMaterial` gains texture references (albedo, normal, ORM), so a new material is a new `.tres` and textures, with no code (CLAUDE.md "content is data").
- **Carved faces are stamped at runtime.** Wild, Gem and Spark ship as small tiles. When a carved die enters play, its material atlas is copied and the carving tile is stamped onto the right face, cached per (material, carving, face).
- **States in the Smoke Room language.** Locked: amber ring on the felt under the die, replacing the green tint. Dead slot: dimmed, static. Cascade flash: amber pulse. Each die gets a soft blob contact shadow, which is cheaper than real-time shadows on the transparent SubViewport.
- **Asset pipeline.** `tools/art_direction/lockdown_art.py` gains a production export: per-material atlases with no baked carvings, the three carve tiles (adding Gem, which the style-frame export lacked), and the die mesh. Output goes to `res://assets/dice/`, imported as ASTC 4×4 (mobile) / lossless where the spec's compression finding requires it.
- **Spec cleanup:** the dice-tumble requirement "Selectable tumble renderer" (2D vs 3D) is removed. The 2D renderer was cut at the M0 spike (PRD §10.1).

## Decisions for you

1. **Carved faces: runtime stamping (recommended)** vs pre-baked atlases for every material × carving × face combination. Stamping keeps texture memory and the asset count flat as M2 adds materials and carvings. Pre-baked is simpler code but grows multiplicatively.
2. **Lock indicator: amber ring under the die (recommended, as in the frame)** vs keeping a tint on the die. A ring leaves the die's material readable while locked; a tint washes it out.
3. **Performance check without a phone.** Your local-only rule means no device test. I propose measuring frame time on desktop in the Compatibility renderer with 8 dice tumbling, and reporting it next to the asset budgets as a stand-in, stated as such. Is that acceptable, or do you want a different bar?

## Capabilities

### New Capabilities
- None.

### Modified Capabilities
- `dice-tumble`: the tumble orients each die to its face (presentation only, determinism unchanged); taps resolve against projected die positions; "Selectable tumble renderer" is removed.
- `dice-materials`: `DiceMaterial` carries visual texture references; carved faces are stamped from carve tiles.
- `art-direction`: records the production dice asset paths and the import compression for die atlases.

## Impact

- `scripts/viewport_3d_dice_tumbler.gd`: largely rewritten (mesh dice, orient-to-face animation, tilted camera, projected rects, ring/blob/flash states). `scripts/dice_tumbler.gd`: `die_rect` becomes renderer-provided; the 2D slot grid goes away.
- `scenes/throw/throw_scene.gd`: passes the drawn dice (material, carving) to the tumbler; otherwise unchanged.
- `scripts/dice_material.gd` + `resources/dice_materials/*.tres`: texture fields. New `res://assets/dice/` (LFS).
- Tests: orientation math (each face lands up), projected tap rects ≥ 126 px, the carve stamp lands on the right tile, determinism (animation never touches the RNG). The desktop playthrough gains screenshot checks of the new dice.

## Non-goals

- Tray, backdrop, lamp pool, grain/vignette overlay (Smoke Room table change).
- UI theme, fonts, HUD (Smoke Room UI change).
- Charm icons and the icon field (separate content change).
- Gold, Echo, Cursed materials and Bomb/Skull faces (M2).
- On-device performance measurement (owner policy: local-only).
- Any gameplay rule: faces, timing, scoring and Heat are untouched.
