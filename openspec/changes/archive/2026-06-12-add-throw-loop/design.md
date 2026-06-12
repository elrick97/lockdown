# Design: add-throw-loop

## Context

First gameplay change. The scaffold provides `RngCore`/`RngService` (seeded streams) and headless GUT runs. The rendering spike (2D vs 3D dice) is undecided, so the throw must be built so either option slots in as presentation. M0's kill-gate rides on how this loop feels; the architecture's job is to make tuning cheap (every feel parameter a named tunable) and correctness testable headless.

## Goals / Non-Goals

**Goals:**
- The full throw playable on screen with gray-box squares, and the full state machine testable headless with synthetic `delta` feeds.
- Per-window remaining times exposed exactly as `add-scoring` will need them.
- Window duration, tumble duration, forgiveness radius, countdown — all tunables changeable in one place.

**Non-Goals:**
- Scoring/Heat math, round structure, materials, real visuals, audio, Steady Mode (but see D2 — the timer design leaves the untimed seam open).

## Decisions

**D1 — Logic/presentation split: `ThrowController` (plain `RefCounted`) + `ThrowTray` scene.**
`ThrowController` owns the state machine, bag draw, faces, locks, and timers. Its only inputs are `tick(delta: float)` and `lock_die(index: int)`; it emits signals (`window_started`, `die_locked`, `reroll`, `resolved`). The scene layer renders state and forwards input. GUT tests drive the controller directly — no scene tree, no waiting on real time.
*Alternative:* state machine as scene nodes (Godot-idiomatic for UI) — rejected; it welds gameplay to the scene tree and kills headless testing (architectural law).

**D2 — Time enters only through `tick(delta)`.**
The scene calls `controller.tick(delta)` from `_process`. The controller never reads clocks, frames, or physics. Frame-rate independence is then a unit test (feed 1/30 vs 1/60 sequences), and Steady Mode later becomes "don't tick" — the untimed seam falls out for free.

**D3 — Per-window remaining time, recorded at window end.**
`remaining[i] = max(0, duration - accumulated)` captured when window `i` ends by expiry or by all-locked; unstarted windows (early resolution) record full duration. Stored as a 3-element array on the resolve payload. Known trade-off: the focus-loss full-timer restore means a backgrounded window can report more remaining time than honest play — accepted per PRD §5 ("generous beats fragile"); the obscured tray removes the study incentive, and M2 telemetry will show whether abuse is real before Heat balance hardens.

**D4 — Geometry stays in the scene layer.**
Tap forgiveness (nearest unlocked die within `tap_forgiveness_radius_px`) is resolved by `ThrowTray` in screen space; the controller only ever sees `lock_die(index)`. Logic stays coordinate-free and headless; forgiveness is tuned visually where it lives.

**D5 — Tunables as a `ThrowConfig` resource (`.tres`).**
`tumble_duration_s`, `lock_window_duration_s`, `tap_forgiveness_radius_px`, `resume_countdown_s` on one `Resource` injected into the controller. Playtest variants (2.0/2.5/3.0 s windows) become swap-in files, matching the data-driven content convention.

**D6 — Focus loss via engine notifications, handled in the scene layer.**
`NOTIFICATION_APPLICATION_FOCUS_OUT` (+ `NOTIFICATION_APPLICATION_PAUSED` for Android) → `get_tree().paused = true` + opaque cover. Resume runs the countdown, then calls `controller.restart_window()` (locks kept, accumulator zeroed) — the controller exposes that one method rather than serializing mid-window state, which keeps the mid-run save format (M2) to between-throws snapshots only.

## Risks / Trade-offs

- [Tap latency makes locks feel mushy] → lock applies same frame as input in `ThrowTray`; juice/feedback later, but correctness now.
- [Gray-box squares mislead playtest feel vs real tumbling dice] → accepted for M0; the spike decision replaces presentation without touching the controller (D1).
- [Desktop testing lacks real focus-loss semantics of Android] → notification path is shared; verify on device when the Android export change lands.

## Open Questions

- None blocking. Heat formula questions stay with `add-scoring`.
