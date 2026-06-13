# Tasks: add-dice-tumble-spike

> Timeboxed spike (PRD: ~1 week). Build only enough to judge feel + perf. Placeholders, not art.

## 1. Tumble seam

- [x] 1.1 `scripts/dice_tumbler.gd` (`DiceTumbler` extends `Control` base): `build`, `begin_tumble(faces, locked, duration)`, `tick(delta)`, `is_settled()`, `reveal`, `lock_die`, `die_rect`; shared grid layout + timing; no RNG access, no gameplay refs
- [x] 1.2 Added `tumble_renderer` enum to `ThrowConfig`; `throw_scene.gd` delegates tumble presentation to the active `DiceTumbler` (build/begin_tumble/tick/reveal/lock_die/die_rect) — inline scramble removed
- [x] 1.3 Determinism + scene-smoke + button + round-smoke tests green with the seam (50/50, faces unchanged, no RNG consumed by presentation)

## 2. Spike A — 2D sprite tumble

- [x] 2.1 Procedural pip rendering instead of binary sprite assets (avoids the .tscn/asset export traps); throwaway placeholder visuals in `sprite_dice_tumbler.gd`
- [x] 2.2 `SpriteDiceTumbler`: dice drawn with pips, slot-machine scramble + settle bounce over `tumble_duration_s`, settling on the predetermined face; locked dice stay static (green)
- [x] 2.3 Verified on device: throw tumbles in 2D, clean pip faces (6,4,5 / 4,4,5), settles before the window opens

## 3. Spike B — 3D SubViewport tumble

- [x] 3.1 3D dice built in code: cube of 6 textured quads (procedural pip faces, no binary assets) + SubViewport with ortho Camera3D and two DirectionalLight3D
- [x] 3.2 `Viewport3DDiceTumbler`: cubes spin to rest (ease-out) showing the predetermined face; SubViewport (560×620 render res, recorded) composited into the tray via `SubViewportContainer` (stretch)
- [x] 3.3 Verified on device: throws tumble in 3D (shaded cubes, readable pips mid-roll and at rest), faces match the seed, settle before the window opens

## 4. Perf comparison harness

- [x] 4.1 Top-left overlay showing active renderer + smoothed FPS (`Engine.get_frames_per_second()`), tappable to switch renderers live
- [x] 4.2 The normal full-draw throw (6 dice tumbling at once) is the representative load; both renderers measured under it
- [x] 4.3 Captured on Pixel 9 under full tumble load: **2D = 60 fps, 3D = 61 fps** (both at the 60-cap — flagship can't discriminate, per design risk #1)

## 5. Decision

- [~] 5.1 Comparison done (perf tie on flagship; choice rests on feel) — awaiting user's 2D-vs-3D call (design-pillar judgment)
- [ ] 5.2 Log the decision + rationale + the captured numbers in **PRD §10.1** (open question #5), with the Pixel-9-upper-bound + needs-mid-range-confirmation caveat
- [ ] 5.3 Delete the losing renderer's spike code; keep the seam + chosen renderer

## 6. Wrap up

- [x] 6.1 Full headless suite green via `tools/run_tests.ps1` (50/50 with the seam + both renderers)
- [ ] 6.2 Update `TASKS.md`: tick Spike A, Spike B, and the perf-test/decision boxes with `add-dice-tumble-spike`
- [ ] 6.3 Commit
