## MODIFIED Requirements

### Requirement: Production dice assets
Production dice assets SHALL live under `res://assets/dice/`, exported by `tools/art_direction/lockdown_art.py`:
- the die mesh (`die.glb`);
- per-material atlases (`<material>_albedo/normal/orm.png`);
- carve tiles (`<material>_<carving>_albedo/normal/orm.png`);
- the blob-shadow sprite;
- the lock signifiers from `export_lock_signifiers()`: `lock_socket.png` (256², a brass rounded-square socket with an amber lip), `padlock.png` (128², a brass padlock), and `crack.png` (256², a fracture overlay).

Die atlases and carve tiles SHALL be imported lossless, so carvings can be stamped at runtime and saturated inlay edges don't stair-step under block compression (style-frame finding). Their dimensions SHALL stay multiples of 4. Palette values SHALL follow the Smoke Room requirement.

#### Scenario: Assets regenerate from the script
- **WHEN** the production exports run in Blender
- **THEN** every file above is written to `res://assets/dice/` with the Smoke Room palette, and `tools/art_direction/check_assets.py` reports no budget violations
