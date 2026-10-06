## ADDED Requirements

### Requirement: Production table and overlay
The game SHALL draw the Smoke Room table on every screen from production assets in `res://assets/table/`, exported by `tools/art_direction/lockdown_art.py`:
- `felt.png` (1024×1024): oxblood felt with the lamp pool, wall AO and a dark leather rim with a brass line, painted in, drawn behind the dice in the tray band;
- `backdrop.png` (1024×2048): dark walnut with the pool's falloff painted in, drawn full-screen behind everything.

Both SHALL import as lossy WebP. One full-screen overlay SHALL apply film grain and a vignette using the Smoke Room tunables (`grain` = 0.07, `vignette` = 0.6, `scanlines` = 0, `chroma_offset_px` = 0), with grain advancing at a fixed 24 steps per second. The overlay SHALL NOT intercept input.

#### Scenario: Table on the throw screen
- **WHEN** the throw screen is shown
- **THEN** the backdrop fills the screen, the felt fills the tray band behind the dice, and the overlay covers everything

#### Scenario: Overlay passes taps through
- **WHEN** the player taps a die or a button under the overlay
- **THEN** the tap reaches it as if the overlay weren't there

#### Scenario: Assets regenerate from the script
- **WHEN** the production table export runs in Blender
- **THEN** `felt.png` and `backdrop.png` are written with the Smoke Room palette, and `tools/art_direction/check_assets.py` reports no budget violations
