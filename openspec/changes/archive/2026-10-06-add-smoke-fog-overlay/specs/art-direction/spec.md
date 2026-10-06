## MODIFIED Requirements

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
