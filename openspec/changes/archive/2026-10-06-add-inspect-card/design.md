## Decisions

### D1: One component, data-driven
`InspectCard.show_item(res, bottom_y, show_cost)` reads `display_name`, `description`, `icon` and `cost`. The type tag comes from the resource class. New items need no card code.

### D2: Never steals input
The card and its scrim are `MOUSE_FILTER_IGNORE`. Dismissal happens in `_input` on any press without consuming the event. Openers act on *release* (`UiStyle.pickable`) or on Button `pressed`, which fires on release. So tapping another item closes the card on the press and reopens it for the new item on the release.

### D3: Draw order
The card sits at z 10 and the scrim at z 9, so the card draws over the HUD and the end panel. The focus cover stays the last child of the throw scene.
