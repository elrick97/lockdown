## ADDED Requirements

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
