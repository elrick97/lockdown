## Context

The throw scene renders dice as `ColorRect` squares whose labels flip during the scramble and snap to the real face on window start (`throw_scene.gd`). The faces are decided up front by `RngService` (throw-loop spec); the tumble is pure presentation. There is no real tumble animation yet, and no decision on the rendering approach for one. PRD §10.1 open question #5 ("2D sprite vs 3D-in-SubViewport dice") is the fork this spike resolves, gated on mid-range Android frame time — now measurable since `add-android-export` shipped.

This is a **spike**: throwaway comparison code whose deliverable is a logged decision, not production presentation. The losing approach is deleted; the winner is hardened in M1's juice pass.

## Goals / Non-Goals

**Goals:**
- Two minimal-but-representative tumble renderers (2D sprite, 3D SubViewport) animating to predetermined faces.
- A renderer-selection seam so the same seeded throw can be viewed under either on-device.
- A frame-time/FPS readout to compare them on the reference Android device.
- A decision recorded in PRD §10.1.

**Non-Goals:**
- Final art, materials, juice, feel-tuning, low-end perf, or shipping both (see proposal Non-goals).

## Decisions

### 1. A pluggable `DiceTumbler` seam, not two forks of the scene
**Decision:** Define a thin tumble-renderer interface the throw scene drives (`begin_tumble(faces)`, `is_settled()`, `show_face(i)`), with two implementations: `SpriteDiceTumbler` (2D) and `Viewport3DDiceTumbler`. Selection via a `ThrowConfig`/debug flag.

**Why:** Keeps the A/B comparison honest (identical throw, identical timing seam, only the renderer differs) and keeps the throw scene's gameplay code untouched. Avoids duplicating the scene per approach.

**Alternative considered:** Two separate throw scenes. Rejected — duplicates the loop and makes a clean A/B swap harder.

### 2. Animation-curve tumble, never physics
**Decision:** Both renderers reach the predetermined face via tweens/animation curves over `tumble_duration_s`. No `RigidBody`/physics simulation drives the result.

**Why:** Architectural law (PRD §6) — physics is non-reproducible across devices/frame rates and must never determine outcomes. The face is fixed before motion starts; motion only animates *to* it. This also keeps the determinism tests valid.

**Alternative considered:** Physics dice that "happen" to land on the face. Rejected outright — violates determinism and the headless balance sim.

### 3. 3D dice live in a `SubViewport` composited into the 2D tray
**Decision:** Spike B renders 3D dice meshes in a `SubViewport`, displayed via a `SubViewportContainer`/`TextureRect` placed in the existing tray layout, so 3D dice occupy the same on-screen slots as the 2D ones.

**Why:** Portrait 2D UI is the frame; 3D is an inset. This is the realistic integration and the one whose perf is in question (extra viewport + 3D pass on a mid-range GPU).

### 4. On-device perf readout is a simple frame-time overlay
**Decision:** A minimal label showing smoothed FPS / frame time (ms), toggled in the spike build, sampled during a scripted representative throw (full draw of dice tumbling at once).

**Why:** The decision needs a number, not a profiler session. Cheap, on-device, comparable across A and B under the same throw.

## Risks / Trade-offs

- **[Reference-device gap]** The verdict targets a *mid-range* device but our test hardware is a Pixel 9 (flagship) — exactly the tier where 3D-SubViewport cost is hidden. → Treat Pixel 9 as a generous upper bound: if 3D struggles even here, it's out; if it's smooth, log the decision with an explicit "needs mid-range confirmation" caveat rather than treating it as final.
- **[Spike scope creep]** Easy to over-polish either renderer. → Timebox (PRD: 1 week); build only enough to judge feel + perf; no art beyond throwaway placeholders.
- **[Seam leaking into gameplay]** A renderer seam could tempt presentation logic into the controller. → The seam lives entirely in the scene/presentation layer; `ThrowController` and scoring stay untouched and headless.
- **[Determinism regression]** New tumble code could accidentally consume RNG or gate outcomes on animation. → Keep the existing determinism tests green; the renderer receives already-decided faces and returns nothing that feeds back into logic.

## Open Questions

- Which `tumble_duration_s` makes the two approaches comparable without favoring one? (Use the current default; not a tuning exercise.)
- Does the 3D SubViewport need a fixed render resolution to stay cheap, or can it match the tray rect? (Decide during Spike B; record what was used alongside the perf numbers.)
