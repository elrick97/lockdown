## Context

`UiStyle.theme()` builds flat `StyleBoxFlat`s. The kit is rendered in Blender at 100 px per unit from explicit solids: bevelled brass rings, inset lacquer or walnut faces, stitched leather with rivets, all lit by the Smoke Room lamp plus a warm world for the brass to reflect.

## Decisions

### D1: StyleBoxTexture 9-patch
`UiStyle` loads the kit and builds a `StyleBoxTexture` per piece and state: texture margins per the spec, axis stretch `STRETCH` (tiling repeated the bezel highlights and showed seams in the leather; stretched centre texture reads cleaner), and content margins that keep text inside the bezel. Hover is the normal texture with `modulate_color` 1.12.

### D2: Timer
`_timer_track` becomes a `NinePatchRect` with `timer_frame`. The existing `TimerBar` node (whose width the scene animates) turns transparent and gets a child `NinePatchRect` with `timer_fill`, anchored full-rect, so the fill follows the bar's width with no change to the timing code.

### D3: Plaques and sockets
- **Plaques:** a `PlaquePanel` theme variation (a Panel with the plaque texture) sits behind the round total on the HUD and behind the shop's gold readout.
- **Sockets:** charm slots (`SlotButton`) use the socket for normal, hover and pressed; the disabled (empty) slot is the socket dimmed to 55%.

### D4: Text depth
- Labels: `font_shadow_color` black at 70%, offset (2, 3).
- Buttons: `outline_size` 6 in a dark brown, so cream text reads on red lacquer.

## Risks / Trade-offs

- **Lossless kit size:** 11 small PNGs, ≈ 0.4 MB in the pack. Fine.
