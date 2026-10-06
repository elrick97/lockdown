## Why

The owner's verdict on the live MVP (2026-10-06): the buttons, labels and boxes "look plain and are still not Blender generated, so they still look very poor." The ui-theme change styled Godot's controls with flat StyleBoxes (dark fill and a brass line). That's readable but has none of the material quality of the dice and table. In the Smoke Room direction every surface is a physical thing under the lamp: lacquer, leather, brass, felt. The UI chrome has to match, or the screen reads as a prototype however good the dice look. PRD trace: §5 art direction, §2 *Jackpot payoff*.

**Pillars served:** *Jackpot payoff*: tactile, premium-feeling controls make every press and every number feel worth something. *Readable depth*: material cues tell the player at a glance what's pressable (raised lacquer), what's information (inset plaques) and what's a slot (recessed sockets).

## What Changes

- **Blender-generated UI kit** (`res://assets/ui/`), rendered from modelled, lit geometry like the dice, then sliced for 9-patch scaling:
  - **Primary button** (THROW, PLAY, CONTINUE): oxblood lacquer with a bevelled brass bezel; normal, pressed (sunk, darker) and disabled (dull, unlit) states.
  - **Secondary button** (RE-ROLL, MENU, BUY, trinkets): dark walnut with a thin brass bezel, the same three states.
  - **Panel:** stitched dark leather with a brass frame and corner rivets, for the HUD, shop cards and the end-of-run panel.
  - **Plaque:** an inset brass-rimmed readout for score, target and gold, so numbers read as "information".
  - **Socket:** a recessed brass ring for the charm slots (empty and filled).
  - **Timer:** a brass tube frame with an amber glow fill strip.
- **The theme switches from flat StyleBoxes to these textures** (StyleBoxTexture 9-patch). Layout, sizes and the thumb-zone rules stay as specced in `ui-theme`.
- **Text gets depth:** labels on plaques and buttons gain a subtle dark drop shadow and an embossed look, using the built-in font (owner decision).
- **Asset pipeline:** a new export in `tools/art_direction/lockdown_art.py` with budget checks: each piece ≤ 512 px, imported lossless so the 9-patch edges stay crisp.

## Capabilities

### New Capabilities
- None.

### Modified Capabilities
- `ui-theme`: theme pieces come from the Blender UI kit (states, 9-patch margins, text shadow) instead of flat colour boxes.
- `art-direction`: production UI kit paths and budgets.

## Impact

- `tools/art_direction/lockdown_art.py`: UI kit modelling and rendering (orthographic, lamp-lit, alpha background) plus slicing metadata.
- `scripts/ui_style.gd`: `StyleBoxTexture` per piece and state; label shadow constants.
- `throw_scene.gd`, `shop_scene.gd`, `start_scene.gd`: use the plaque, socket and timer pieces where they now use plain labels or rects.
- Tests: theme pieces are textures, not flat boxes; 9-patch margins keep controls ≥ 126 px; the asset budget check passes. Playthrough screenshots of every screen.

## Non-goals

- New fonts or a logo (name decision pending).
- Charm icons (`add-charm-icons`).
- Animation or feedback (`add-score-feedback`).
- Changing layout or sizes (the `ui-theme` rules stand).
