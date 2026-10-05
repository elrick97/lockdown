## Why

Every M1 system now runs on gray boxes and procedural pip textures. The next presentation items in TASKS.md ("UI layout pass", "Placeholder → first-pass dice/charm art", and the devlog) all need one decided visual target first. PRD §5 names a candidate ("back-alley dice den": felt, neon accents, CRT-adjacent grain, readable at speed) but leaves it untested. This change turns that candidate into 3 concrete, budget-honest style frames so one can be picked before any production art is made. It traces to PRD §5 (Art direction), §10 Q4 (name still open, so no signage) and the §10.1 caveat (mid-range performance unconfirmed, so every frame is built to a mobile budget, not a beauty-render budget).

**Pillars served:** *Readable depth*: dice must read at a glance mid-tumble and at the 48 dp tap size. *Jackpot payoff*: the look carries the spectacle and is the devlog's main asset. Secondary: *Collect & unlock*: Bone, Iron and Glass must look collectible and be distinguishable at a glance.

## What Changes

- Build **3 distinct style frames** in Blender (driven through the Blender MCP server), each a portrait **1080×2400** render of the run screen's composition (PRD §5 layout: HUD band top, tray in the middle 50%, charm row and throw area bottom):
  - **A: Felt & Neon.** The PRD candidate played straight: deep-teal felt tray, warm tungsten key light, magenta/cyan neon rim accents, light CRT grain.
  - **B: Smoke Room.** Restraint test: oxblood/charcoal felt, one hard overhead lamp pool, a single amber accent, heavy contrast, film grain.
  - **C: Arcade Cabinet.** Graphic and bold: saturated purple felt, flat/toon-baked shading, thick silhouettes, scanline overlay. This is the most readable direction by construction.
- Every frame contains: the dice tray; dice in **Bone, Iron and Glass**; at least one **carved face** (Wild, Gem or Spark); one **charm icon** (proposed: *Hair Trigger*); and a **readability strip** showing each die at 48 dp equivalent (~126 px at base resolution), mid-tumble with motion blur, and in grayscale.
- HUD and buttons appear only as neutral placeholder shapes. **No logo, title or name text**, and neon accents use pictograms only (die, bolt, arrow).
- Every asset is built as it would ship: low-poly meshes, **baked textures** (lighting and AO baked into albedo), Glass **faked** (fresnel rim, baked inner highlights, optional alpha; no transmission, refraction or screen-texture reads), and grain/scanlines treated as one cheap full-screen overlay that Godot can reproduce. Each frame's dice export to **glTF** and import into Godot 4.6 (GL Compatibility) for a side-by-side check against the render.
- Outputs land in `/assets/art_direction/`: three frame PNGs, a comparison sheet, the `.blend` sources and a per-frame asset sheet (palette hexes, tri counts, texture sizes, draw-call estimate).
- After the pick: the decision gets logged in PRD §5, the same way §10.1 was, and the chosen frame's budgets become the living `art-direction` spec.
- **Repo plumbing:** CLAUDE.md says `/assets` uses git-lfs, but `.gitattributes` has no LFS rules yet. This change adds LFS tracking for `*.blend`, `*.glb` and the large art PNGs under `/assets/art_direction/` (git-lfs 3.7.1 is already installed; this adds no new dependency).

## Capabilities

### New Capabilities
- `art-direction`: the visual target and the asset contract that all later art must honor. It covers the chosen style (palette, lighting model, post overlay), **named budget tunables** (die tri count, texture resolution per material, tray budget, lights, overlay passes; values drafted in design.md for a 2021 mid-range Android in GL Compatibility), readability requirements (48 dp grayscale legibility, mid-tumble legibility, materials distinguishable by value/texture and not by hue alone, which keeps the M2 color-blind work cheap), export format (glTF, ETC2/ASTC-safe textures) and asset provenance (original work only; any third-party or AI-generated asset needs the owner's license approval first).

### Modified Capabilities
- None. `dice-tumble`, `dice-materials` and `shop-scene` behavior is unchanged; nothing in-game changes in this change.

## Impact

- **Code:** none. No scenes, scripts or resources are touched.
- **Repo:** new `/assets/art_direction/` (renders, `.blend` sources, glTF test exports, asset sheets); `.gitattributes` gains LFS rules.
- **Tooling:** Blender 5.2 + `mcp-for-blender` (already set up). Its asset libraries and 3D generators stay **off**: everything is modeled and painted from scratch, so no license questions arise.
- **Downstream flag:** today's 3D tumbler (`scripts/viewport_3d_dice_tumbler.gd`) swaps one texture onto all six quads, so a die shows the same value on every side. Every style frame assumes real six-faced dice. The later "first-pass dice/charm art" change will therefore need a `dice-tumble` presentation change: orient a six-face mesh to the result instead of swapping textures. That is out of scope here; I'm noting it so it isn't a surprise.
- **Pending work untouched:** the six M1 changes awaiting on-device verification stay unarchived.

## Non-goals

- In-game integration of any art (separate TASKS item "Placeholder → first-pass dice/charm art").
- On-device performance measurement (the budgets are designed for the target phone; verification happens at integration).
- HUD/UI art, typography, iconography beyond one charm, the logo or the name (PRD Q4).
- Art for the other 11 charms, Gold/Echo/Cursed materials, or Bomb/Skull faces (M2).
- Animation, VFX, screen shake, haptics or audio (the juice pass is a Godot job).
- Color-blind palettes themselves (M2). This change only keeps them cheap by not encoding material in hue alone.
