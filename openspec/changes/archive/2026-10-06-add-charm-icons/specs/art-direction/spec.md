## ADDED Requirements

### Requirement: Production charm icons
`export_charm_icons()` in `tools/art_direction/lockdown_art.py` SHALL render each charm medallion from modelled geometry:
- a bevelled brass rim with beading;
- a clear-coated enamel face;
- a raised ivory emblem.

Each medallion is rendered 256×256 with alpha into `res://assets/charms/`, under the Smoke Room lamp setup. Icons import lossless with mipmaps, so they downsample cleanly to slot size.

#### Scenario: Icons regenerate from the script
- **WHEN** the charm icon export runs in Blender
- **THEN** 12 PNGs are written at 256×256 and `check_assets.py` reports no problems
