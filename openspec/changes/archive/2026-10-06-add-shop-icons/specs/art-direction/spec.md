## ADDED Requirements

### Requirement: Production shop icons
`export_shop_icons()` in `tools/art_direction/lockdown_art.py` SHALL render 256×256 icons with alpha into `res://assets/shop/`, under the Smoke Room lamp:
- **Dice offers** (`iron`, `glass`, `wild_6_bone`, `gem_5_bone`, `spark_4_bone`): the production die mesh with its material atlas (carved face up), in 3/4 view on a dark felt coaster with a brass rim. Carved dice add a faint amber ring.
- **Trinkets** (`re_tumble`, `freeze_timer`): a walnut gaming chip with brass edge inserts and a raised ivory emblem, top-down.

Icons import lossless with mipmaps. Temporary atlases go to the temp dir, never the repo.

#### Scenario: Icons regenerate from the script
- **WHEN** the shop icon export runs in Blender
- **THEN** seven 256×256 PNGs are written and `check_assets.py` reports no problems
