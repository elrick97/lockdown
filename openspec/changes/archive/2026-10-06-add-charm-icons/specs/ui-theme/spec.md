## ADDED Requirements

### Requirement: Charms show as medallions and pulse when they fire
Wherever a charm appears, it SHALL show its medallion:
- **Throw screen charm slots:** the icon over the socket. Tapping a slot shows the name and rule in the status line.
- **Shop offer cards:** the icon left of the text, for charms only.
- **Shop owned row:** the build as medallions, with empty slots as dim sockets.
- **End-of-run panel:** the run's build, shown the same way as the shop owned row.

During the score cascade, after the combo label pops, each slot in `charm_triggers` SHALL pulse in slot order, `charm_pulse_gap_s` (current 0.18 s) apart. A pulse scales the slot to about 1.28×, brightens it, then settles elastically.

#### Scenario: Only firing charms pulse
- **WHEN** a throw is scored and only some owned charms changed the score
- **THEN** exactly those slots pulse

#### Scenario: Build visible in the shop
- **WHEN** the shop opens with 3 charms owned
- **THEN** the owned row shows 3 medallions and 2 empty sockets
