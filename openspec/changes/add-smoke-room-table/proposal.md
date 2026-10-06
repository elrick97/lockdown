## Why

The Smoke Room dice now sit on a flat gray background. The direction's mood comes from the table: oxblood felt in a single hard lamp pool, near-black surroundings, film grain and a strong vignette (`art-direction` spec, "Chosen visual direction is Smoke Room"). The spec requires the lamp pool to be painted into textures so it survives without real-time light. This is the table half of the art pass, alongside the dice (`add-smoke-room-dice`, done) and the UI (`add-smoke-room-ui`). PRD trace: §5 art direction.

**Pillars served:** *Jackpot payoff*: the lamp-lit felt is the stage the dice and the score cascade play on. *Readable depth*: the pool keeps the eye on the tray and pushes the HUD/charm areas back.

## What Changes

- **Tray:** a felt texture (1024², Smoke Room palette, lamp pool, wall AO and a dark rim painted in) behind the dice SubViewport, sized to the tray band. The dice's blob shadows and lock rings sit on it.
- **Backdrop:** a full-screen dark walnut texture (1024×2048) with the pool's falloff painted in, behind everything.
- **Overlay:** one full-screen canvas shader on top: film grain 0.07, vignette 0.6, no scanlines or chroma (spec tunables), with grain animated at a fixed 24 fps step so it's cheap. It applies to the start and shop screens too, for one consistent look. It reads no input (mouse filter ignore).
- **Assets** come from the Blender script's production export (`res://assets/table/`), with the same budget checks as the dice. The textures import VRAM-compressed (no runtime stamping needed).
- **Frame-time check:** `tools/perf_dice.gd` is extended to include the table and overlay, still reported as a desktop stand-in.

## Capabilities

### New Capabilities
- None.

### Modified Capabilities
- `art-direction`: production table assets and overlay parameters (paths, sizes, overlay values as the shipped tunables).

## Impact

- `tools/art_direction/lockdown_art.py`: `export_production_table()`. New `res://assets/table/` (LFS), `resources/ui/overlay.gdshader`.
- `throw_scene.gd`/`shop_scene.gd`/start scene: backdrop + tray texture + overlay layer, layout in code.
- Tests: overlay ignores input; textures within budget; the tray texture fills the tray band. Desktop playthrough screenshots and the perf report.

## Non-goals

- Real-time lighting or shadows on the table (painted, per spec).
- Neon signage, logo or name.
- UI theme (separate change), audio (deferred).
