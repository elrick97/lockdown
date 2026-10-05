## ADDED Requirements

### Requirement: Chosen visual direction is Smoke Room
Game art SHALL follow the "Smoke Room" direction (chosen 2026-10-05; reference `assets/art_direction/frame_b_smoke_room.png` and its asset sheet). Named tunables, current values:
- `palette_felt` = #5C0D0F, `palette_rim` = #210D09, `palette_backdrop` = #1C110A.
- `palette_accent` = #FF9E29 (amber: lock rings, timer, score value), `palette_ui_line` = #CC994C (brass).
- Dice: `palette_bone` = #E0CCA3 with pips #1F0F0A (the 1-pip #850F0D); `palette_iron` = #454547 with pips #FAD68F; `palette_glass` = #FAA338 with pips #FFF7E6.
- Carved inlays: Wild #F5B852, Gem #BF141F, Spark #FFF7E0.
- Lighting: `lamp_pool` = one warm overhead key (#FFDBA8) whose falloff is also painted into the felt (centre ×1.32, base ×0.42, radius 3.0 world units) and the backdrop. Optional cool fill #99B2FF at low energy. `ambient` = #030202.
- Overlay: `grain` = 0.07, `vignette` = 0.6, `bloom_threshold` = 0.8, `bloom` = 0.35, `scanlines` = 0, `chroma_offset_px` = 0.

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
