## Context

Charms were text in slots and on cards. The scoring engine already fires `on_score` in slot order, which is the natural place to see which charm did something.

## Decisions

### D1: Icons are data
`CharmEffect.icon` is an exported `Texture2D` on each `.tres`. Screens read it generically.

### D2: Trigger detection by before/after deltas
The engine snapshots chips and mult around each `on_score` call. This catches charm-chip and charm-mult adds as well as rewrites (Snake Charmer sets `combo_mult` and zeroes `bonus_chips`). Charms need no new API. The record lives on `ScoreBreakdown`, where the cascade already reads.

### D3: Pulse is driven by the cascade
`ScoreCascade` emits `charm_triggered(slot)` per entry, after the combo label, spaced by `CHARM_PULSE_GAP_S`. `ThrowScene` tweens the slot: scale and modulate pop, then an elastic settle. `skip()` simply never emits.

### D4: Medallion geometry
- **Rim:** brass prism, r 1.18, with bevel and 24 beads.
- **Face:** enamel disc, r 0.96, with clear coat.
- **Emblem:** ivory, built from extruded polygons and thick strokes (quads plus round joints), with dark ink discs for pips and eyes.
- **Render:** top-down ortho at 100 px per unit, 256².

### D5: Shared helpers
`UiStyle.charm_badge(icon, px)` is a mipmapped TextureRect. `UiStyle.charm_row(charms, slots, px)` builds a row of medallions and dim sockets, used by the shop and the end panel.

## Risks / Trade-offs

- **Pack size:** 12 small PNGs, about 0.6 MB.
- **Shop icons:** dice, trinket and carved-die offers still show no icon. They are out of scope; a later content pass can add them.
