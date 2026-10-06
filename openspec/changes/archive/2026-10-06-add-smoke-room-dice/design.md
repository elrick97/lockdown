## Context

Today `Viewport3DDiceTumbler` builds each die from six quads sharing one material and swaps a procedurally drawn face texture to show the current value. The camera is orthographic, looking straight down. Tap rectangles come from a fixed 2D grid in `DiceTumbler` (220 px slots), independent of the 3D camera. The tumbler doesn't know each die's material or carving. The style-frame work produced the Smoke Room die recipe in `tools/art_direction/lockdown_art.py` (188-tri beveled die, 768×512 atlas, Glass faked) and showed that it renders closely in GL Compatibility.

## Goals / Non-Goals

**Goals:** Smoke Room dice in game with orient-to-face tumbles, the 18° tilt, taps that match what's drawn, runtime carve stamping, and ring/dead/flash/blob states. Material visuals as data. Determinism untouched.

**Non-goals:** table, overlay, UI theme, charm icons (see proposal).

## Decisions

### D1: Production export from the existing Blender script
Add `export_production_dice()` to `lockdown_art.py`. It writes to `res://assets/dice/`:
- `die.glb`: the mesh only, PBR-free; the renderer builds materials.
- Uncarved atlases per material (Bone, Iron, Glass; Smoke Room palette).
- For each material × carving (Wild, Gem, Spark): a 256² tile per map, the carving drawn on that material's face background.
- `lock_ring.png` and `blob_shadow.png` (128², generated).

`check_assets.py` gains these paths and budgets. The style-frame folder stays untouched as the decision record.

### D2: Visual fields on `DiceMaterial`
Add `@export var albedo/normal/orm: Texture2D`, `transparent: bool`, `rim: float`. The renderer builds one `StandardMaterial3D` per die: albedo + normal + ORM (AO/roughness/metallic channels); for Glass, `transparency = ALPHA`, rim enabled, and a small emission from albedo. Per-die instances are needed because states (dim, flash) animate per die.

### D3: Stamping
`DieAtlasCache` (RefCounted, presentation-only) maps `(material_id, carve_type, face)` to stamped `ImageTexture` triples. On a miss it calls `get_image()` on the material's lossless atlases, duplicates them, `blit_rect`s the carve tile into the face's tile rect (col = (face−1) % 3, row = (face−1) / 3, 256 px), generates mipmaps and wraps the result in `ImageTexture`. Lossless import makes `get_image()` return RGBA8, so the blit is valid. Uncarved dice use the material's textures directly. Memory: ≤ 8 stamped variants × 3 maps × 1.5 MB.

### D4: Orientation math
Blender exports Z-up to glTF Y-up, so the in-game layout is +Y=1, −Y=6, +X=3, −X=4, −Z=2, +Z=5. `face_up_basis(v, yaw)` = rotation taking face v's normal to +Y, then a yaw about +Y with `yaw = slot_yaw[slot]`, a fixed table of small angles (±15°). The animation keeps today's shape: `basis(t) = face_up_basis * Basis(spin_axis[slot], (1 − ease(t)) × 3·TAU)`, so it ends exactly on the target. `spin_axis` is the existing slot-derived axis; nothing reads the RNG.

### D5: Camera, viewport and tap rectangles
The SubViewport's resolution matches the tray's aspect at `render_scale` (0.6 of tray pixels, a tunable carried over from the spike's fill-cost choice). The camera is orthographic, rotated −(90° − 18°) about X, framing the grid with a margin. `die_rect(i)` projects the 8 corners of die i's bounding box with `Camera3D.unproject_position`, scales by tray size / viewport size, offsets by the tray's global position, and returns the bounds. The world die size and grid spacing are chosen so a settled die spans ≥ 126 px on screen with 8 dice (4 × 2 grid). `DiceTumbler._slot_rect` and the 2D constants are removed; `die_rect` becomes a renderer override.

### D6: States
- Ring: an unshaded quad on the floor plane (y = 0) under each die with `lock_ring.png` tinted amber, visible when locked.
- Blob shadow: a quad with `blob_shadow.png`, multiply-blended, always on.
- Dead: `albedo_color` scaled to 0.45, no ring.
- Flash: a tween of `emission` (amber) up and back; it replaces the green `COLOR_LOCKED` tween.

`throw_scene.gd` passes the drawn dice to `build()` (material id, carved face, carve type per slot) so the renderer can pick materials. That's the only scene change.

### D7: Lighting
Inside the SubViewport's own world: one `DirectionalLight3D`, warm key #FFDBA8 from above-front without shadows, and a `WorldEnvironment` with a low ambient (Smoke Room ambient lifted enough that dark Iron stays readable on felt). This fits the light budget (1 directional).

### D8: Desktop frame-time stand-in (owner-approved)
A `tools/perf_dice.gd` script runs the throw scene windowed at 1080×2400 with 8 dice continuously re-tumbling for 20 s, vsync off, and reports average and 95th-percentile frame time. It's reported next to the asset budgets and labelled as a desktop stand-in, not a phone measurement.

## Risks / Trade-offs

- **Lossless die atlases** cost VRAM (~12 MB worst case) instead of compression. That's acceptable for 8 dice and it avoids the inlay artifacts.
- **Ortho tilt changes tap geometry.** Mitigated by projected rects and a minimum-size test.
- **Desktop frame time isn't a phone.** That's accepted by the owner; budgets were designed for the target phone.
- **Glass sorting** with alpha can flicker when dice overlap mid-tumble. Mitigation: per-die `render_priority` by depth from the camera, updated each frame. Cheap with ≤ 8 dice.
