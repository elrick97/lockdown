# art-direction Specification

## Purpose
The visual target and asset contract for all game art: the chosen "Smoke Room" direction, mobile budgets for GL Compatibility on a 2021 mid-range Android phone, readability at tap size and mid-tumble, the six-face die atlas, glTF/ETC2 delivery, no name signage before the name decision, and asset provenance. Established by change `add-art-direction` (2026-10-05).
## Requirements
### Requirement: Chosen visual direction is Smoke Room
Game art SHALL follow the "Smoke Room" direction (chosen 2026-10-05; reference `assets/art_direction/frame_b_smoke_room.png` and its asset sheet). Named tunables, current values:
- `palette_felt` = #5C0D0F, `palette_rim` = #210D09, `palette_backdrop` = #1C110A.
- `palette_accent` = #FF9E29 (amber: lock rings, timer, score value), `palette_ui_line` = #CC994C (brass).
- Dice: `palette_bone` = #E0CCA3 with pips #1F0F0A (the 1-pip #850F0D); `palette_iron` = #454547 with pips #FAD68F; `palette_glass` = #FAA338 with pips #FFF7E6.
- Carved inlays: Wild #F5B852, Gem #BF141F, Spark #FFF7E0.
- Lighting: `lamp_pool` = one warm overhead key (#FFDBA8) whose falloff is also painted into the felt (centre ×1.32, base ×0.42, radius 3.0 world units) and the backdrop. Optional cool fill #99B2FF at low energy. `ambient` = #030202.
- Overlay: `fog_edge` = 0.62, `fog_center` = 0.04, `fog_drift` = 0.015 screen heights/s, `fog_color` = (0.68, 0.60, 0.52), `vignette` = 0.6, `bloom_threshold` = 0.8, `bloom` = 0.35, `grain` = 0, `scanlines` = 0, `chroma_offset_px` = 0.

#### Scenario: Accent is the only saturated hue
- **WHEN** a new UI element or effect needs emphasis
- **THEN** it uses `palette_accent` (amber) or brass, not a new saturated hue

#### Scenario: Lamp pool without real-time light
- **WHEN** the scene renders with the spot light disabled
- **THEN** the tray still shows the lamp-pool falloff, because it is painted into the felt and backdrop textures

### Requirement: Art assets honor the mobile budget
Every shipped 3D art asset SHALL fit the named budget tunables so it runs at 60 fps in Godot 4.6's GL Compatibility renderer on a 2021 mid-range Android phone. Current values: `die_tris_max` = 300, `die_atlas_px` = 768×512 per material variant (albedo, normal, roughness/ORM), `tray_tris_max` = 2000, `tray_texture_px` = 1024², `charm_icon_px` = 256², `scene_lights_max` = 1 directional + 2 omni/spot, `overlay_passes_max` = 1 canvas shader plus optional glow, `draw_calls_est_max` = 40 for a full 8-die tray.

#### Scenario: Die within budget
- **WHEN** a die mesh is exported for the game
- **THEN** it has at most `die_tris_max` triangles and samples only textures no larger than `die_atlas_px`

#### Scenario: Look survives without glow
- **WHEN** a scene is rendered with real-time glow disabled
- **THEN** neon accents still read, because their halos are painted into textures

### Requirement: Materials use game-mappable shading only
Art materials SHALL use only features that map to Godot `StandardMaterial3D` in GL Compatibility: image-texture albedo, normal, roughness, metallic, emission, alpha transparency, rim, and toon diffuse/specular. They SHALL NOT rely on transmission, refraction, screen-texture reads, SSR or volumetrics. Glass SHALL be faked with alpha, painted thickness, a fresnel rim and specular.

#### Scenario: Glass without refraction
- **WHEN** a Glass die is rendered
- **THEN** its look comes from alpha, painted gradient, rim and specular, and no material reads the screen behind it

### Requirement: Dice are readable at tap size and mid-tumble
Dice SHALL be identifiable by value and by material at `die_min_px` = 126 px (48 dp at base resolution), in grayscale, and with tumble motion blur. Materials SHALL be distinguishable by value and texture, not by hue alone.

#### Scenario: Grayscale readability
- **WHEN** Bone, Iron and Glass dice are shown at 126 px in grayscale
- **THEN** each die's pip value and material can be told apart

#### Scenario: Mid-tumble readability
- **WHEN** a die is shown with tumble motion blur
- **THEN** its material is still identifiable from silhouette and value

### Requirement: Dice use a six-face atlas mesh
A die SHALL be a single mesh whose six faces map to six tiles of one atlas in the standard layout (+Z=1, −Z=6, +X=3, −X=4, +Y=2, −Y=5; opposite faces sum to 7). A carved face SHALL be a tile replacement in a variant atlas, not a separate mesh.

#### Scenario: Carved face variant
- **WHEN** a die carries a Wild, Gem or Spark carved face
- **THEN** the same mesh is used with a variant atlas in which the carved tile replaces that face's pip tile

### Requirement: Art is delivered as glTF with compressible textures
3D art SHALL be exported as glTF 2.0 (`.glb`) with PNG source textures whose dimensions are multiples of 4, so Godot can compress them to ETC2/ASTC.

#### Scenario: Import into the project
- **WHEN** a `.glb` asset is imported into the Godot project
- **THEN** it renders in GL Compatibility with its textures VRAM-compressed and no import errors

### Requirement: No name or logo in art before the name decision
Art SHALL NOT contain the game's title, logo or name text until PRD open question #4 is resolved. Signage SHALL use pictograms only.

#### Scenario: Neon signage
- **WHEN** a frame or asset includes neon signage
- **THEN** it shows pictograms (die, bolt, arrow) and no words

### Requirement: Asset provenance is original or approved
Art assets SHALL be original work made for the project. A third-party or AI-generated asset SHALL NOT be added before its license has been approved by the project owner and recorded in the repository.

#### Scenario: Library asset proposed
- **WHEN** a third-party or generated asset is considered
- **THEN** it is not added until the owner approves its license and the approval is recorded

### Requirement: Production dice assets
Production dice assets SHALL live under `res://assets/dice/`, exported by `tools/art_direction/lockdown_art.py`: the die mesh (`die.glb`), per-material atlases (`<material>_albedo/normal/orm.png`), carve tiles (`<material>_<carving>_albedo/normal/orm.png`), and the ring and blob-shadow sprites. Die atlases and carve tiles SHALL be imported lossless, so carvings can be stamped at runtime and saturated inlay edges don't stair-step under block compression (style-frame finding). Their dimensions SHALL stay multiples of 4. Palette values SHALL follow the Smoke Room requirement.

#### Scenario: Assets regenerate from the script
- **WHEN** the production export runs in Blender
- **THEN** every file above is written to `res://assets/dice/` with the Smoke Room palette, and `tools/art_direction/check_assets.py` reports no budget violations

### Requirement: Production table and overlay
The game SHALL draw the Smoke Room table on every screen from production assets in `res://assets/table/`, exported by `tools/art_direction/lockdown_art.py`:
- `felt.png` (1024×1024): oxblood felt with the lamp pool, wall AO and a dark leather rim with a brass line, painted in, drawn behind the dice in the tray band;
- `backdrop.png` (1024×2048): dark walnut with the pool's falloff painted in, drawn full-screen behind everything.

Both SHALL import as lossy WebP.

One full-screen overlay SHALL apply drifting fog and a vignette using the Smoke Room overlay tunables:
- **Fog:** warm smoke from a domain-warped, seamless fractal-noise texture with a fixed seed. It moves continuously at `fog_drift`, rising, with no per-frame noise. Density is `fog_edge` in the side margins, corners and bottom, lighter over the top HUD, and `fog_center` over the play area.
- **Cost:** the overlay SHALL be a single canvas pass with at most four texture samples per pixel.
- **Input:** the overlay SHALL NOT intercept input.

#### Scenario: Table on the throw screen
- **WHEN** the throw screen is shown
- **THEN** the backdrop fills the screen, the felt fills the tray band behind the dice, and the overlay covers everything

#### Scenario: No flicker
- **WHEN** two frames 1/24 s apart are compared at the screen edge
- **THEN** they differ only by the fog's slow drift, never by per-pixel noise

#### Scenario: Overlay passes taps through
- **WHEN** the player taps a die or a button under the overlay
- **THEN** the tap reaches it as if the overlay weren't there

### Requirement: Production UI kit
The UI kit SHALL be rendered from modelled, lamp-lit geometry by `tools/art_direction/lockdown_art.py` (`export_production_ui()`) into `res://assets/ui/`, imported lossless without mipmaps. Pieces and sizes (px):
- `button_{primary,secondary}_{normal,pressed,disabled}`: 256×128
- `panel`: 256×256
- `plaque`: 256×96
- `socket`: 160×160
- `timer_frame`: 512×56
- `timer_fill`: 64×32

Each piece is ≤ 512 px on its long side, with transparent surroundings. 9-patch margins (current): button 40, panel 48, plaque 32, socket 52, timer frame 36 × 26, timer fill 16 × 14.

#### Scenario: Kit regenerates from the script
- **WHEN** the UI export runs in Blender
- **THEN** all eleven pieces are written at their sizes, and `tools/art_direction/check_assets.py` reports no problems

### Requirement: Production charm icons
`export_charm_icons()` in `tools/art_direction/lockdown_art.py` SHALL render each charm medallion from modelled geometry:
- a bevelled brass rim with beading;
- a clear-coated enamel face;
- a raised ivory emblem.

Each medallion is rendered 256×256 with alpha into `res://assets/charms/`, under the Smoke Room lamp setup. Icons import lossless with mipmaps, so they downsample cleanly to slot size.

#### Scenario: Icons regenerate from the script
- **WHEN** the charm icon export runs in Blender
- **THEN** 12 PNGs are written at 256×256 and `check_assets.py` reports no problems

### Requirement: Production start hero
`export_start_hero()` in `tools/art_direction/lockdown_art.py` SHALL render `res://assets/ui/start_hero.png` at 768×640 with alpha, under the Smoke Room lamp, from the shipped production die mesh and Bone atlas:
- a locked six-up die in an emissive amber lock ring inside a brass ring;
- two tumbling dice;
- amber sparks;
- a soft amber halo.

Glow SHALL land on `palette_accent` without clipping to yellow. It SHALL import lossless and contain no name, logo or lettering.

#### Scenario: Hero regenerates from the script
- **WHEN** the hero export runs in Blender
- **THEN** a 768×640 PNG is written to `assets/ui/` and `check_assets.py` reports no problems

