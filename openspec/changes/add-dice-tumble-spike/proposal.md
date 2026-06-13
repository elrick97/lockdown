## Why

The throw loop renders dice as gray-box squares that snap to their faces — there is no tumble, so the moment of suspense before a face is revealed (the heart of a dice game) is absent. Before investing in real dice art, we must decide *how* dice tumble: a 2D sprite approach or a 3D-in-SubViewport approach. That choice is a fork in the rendering road, and the deciding factor is mid-range Android performance — now testable since the export pipeline works. This is a timeboxed spike (PRD §10.1, open question #5): build both cheaply, measure, decide.

**Design pillars served:** Jackpot payoff (the tumble is the anticipation that makes a reveal feel earned); Flow under pressure (tumble timing must read instantly under the lock-window clock). The spike protects these by making the presentation choice on evidence, not vibes.

## What Changes

- **Spike A — 2D sprite tumble:** dice as 2D sprites animating to rest via tween/animation curves over `tumble_duration_s`, settling on the predetermined face.
- **Spike B — 3D SubViewport tumble:** 3D dice meshes tumbling inside a `SubViewport`, composited into the 2D UI tray, rotating to show the predetermined face.
- **A/B harness:** a way to swap the active tumble renderer (config flag or debug toggle) so the same throw can be viewed under either approach on-device.
- **Perf comparison:** capture frame time / FPS for both on the mid-range Android device under a representative throw; record the numbers.
- **Decision:** log the chosen approach and rationale in **PRD §10.1** (open question #5).

Both renderers animate to faces **already decided by `RngService`** before the tumble begins — presentation only, never determining outcomes (architectural law, PRD §6). Determinism tests must stay green: skipping or swapping the animation yields identical faces.

## Capabilities

### New Capabilities
- `dice-tumble`: the presentation contract for the tumble phase — animate unlocked dice to their predetermined faces over the tumble duration without influencing outcomes, and expose a selectable renderer. (Thin: a spike produces a decision; this captures only the invariants both approaches must honor, not the winning implementation's details.)

### Modified Capabilities
*(none — `throw-loop` already specs the tumble as predetermined-then-animated; this spike fills in the presentation, not the rules)*

## Impact

- New: spike scenes/scripts under `scenes/` and `scripts/` for the 2D and 3D tumble renderers; a renderer-selection seam in the throw scene
- Possible new: a few placeholder dice assets (sprite sheet / simple 3D mesh) under `assets/` — throwaway, not final art
- Touches `scenes/throw/throw_scene.gd` only at the seam where the tumble is presented (the controller and scoring are untouched)
- No new third-party dependencies (Godot's built-in 2D, 3D, and SubViewport only)
- Tooling: a lightweight on-device FPS/frame-time readout for the comparison
- PRD §10.1 updated with the decision

## Non-goals

- Final dice art, materials, faces, or juice (M1's first juice pass)
- Physics-driven tumbling — physics must never determine outcomes; any motion is cosmetic and animates to the predetermined result
- Shipping both renderers — the spike picks one; the loser is deleted
- Tuning tumble duration / feel beyond what's needed to judge the two approaches (that's a playtest task)
- Perf work on low-end devices (the decision targets the mid-range reference device for M0)
