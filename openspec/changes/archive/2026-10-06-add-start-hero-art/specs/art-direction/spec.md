## ADDED Requirements

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
