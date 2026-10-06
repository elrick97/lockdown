## Context

All screens lay out in code (the Android anchor gotcha). Labels and buttons use per-node font size overrides; there's no theme. The shop builds offer cards as `HBoxContainer`s and finds each BUY button by child index. The throw scene's trinket row sits at the top (y 645–780), outside the thumb zone.

## Decisions

### D1: Theme built in code, cached
`UiStyle.theme()` (static, cached) builds one `Theme` from the art-direction palette: `StyleBoxFlat`s for Button states, PanelContainer, plus type variations `ThrowButton`, `SlotButton`, `HudValue`, `CardBody`. It's built in code rather than as a hand-authored `.tres`, which keeps palette values next to their spec names and avoids hand-authored resource drift. Scenes set `theme = UiStyle.theme()` on their root, so every child inherits it, including the end panel.

### D2: Throw screen bands (pixels at 1080×2400)
- HUD panel 20–330, with the ante label, throw count and the amber total.
- Status 340–420; cascade readout 430–600.
- Timer: track and amber fill at 615–650.
- Tray 27%–66% (648–1584).
- Charm row 1610–1770: five `SlotButton`s of ≈ 184 × 160 px.
- Trinket/SKIP row 1800–1930: trinkets and SKIP never show at the same time, so they share the row.
- THROW 2100–2280.

### D3: Charm row
Built in `_ready` from `RunCoordinator.inventory` (which can't change on the throw screen). Filled slots show the charm name (wrapped); tapping writes "Name: description" to the status line. Empty slots are disabled with a dot.

### D4: Shop cards
Each card is a `PanelContainer` holding an `HBox[VBox(name · cost, description), BUY]`, with BUY ≥ 220 × 130 px. The scene keeps `_buy_buttons[i]` instead of looking up child indices. Cards occupy 1120–1900 under the gold readout, an owned-charms panel and the status line; RE-ROLL and CONTINUE stay at the bottom.

## Risks / Trade-offs

- **Long charm names in 184 px slots** wrap to two lines at 28 px, which fits within 160 px.
- **The built-in font** is generic. Accepted by the owner until the name decision.
