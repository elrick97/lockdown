## ADDED Requirements

### Requirement: Production dice assets
Production dice assets SHALL live under `res://assets/dice/`, exported by `tools/art_direction/lockdown_art.py`: the die mesh (`die.glb`), per-material atlases (`<material>_albedo/normal/orm.png`), carve tiles (`<material>_<carving>_albedo/normal/orm.png`), and the ring and blob-shadow sprites. Die atlases and carve tiles SHALL be imported lossless, so carvings can be stamped at runtime and saturated inlay edges don't stair-step under block compression (style-frame finding). Their dimensions SHALL stay multiples of 4. Palette values SHALL follow the Smoke Room requirement.

#### Scenario: Assets regenerate from the script
- **WHEN** the production export runs in Blender
- **THEN** every file above is written to `res://assets/dice/` with the Smoke Room palette, and `tools/art_direction/check_assets.py` reports no budget violations
