## Context

Currently `_on_resolved()` in `throw_scene.gd` assigns score labels and re-enables the THROW button in the same frame that `ThrowController` emits `resolved`. The player sees numbers jump from 0 to final instantly. `ScoreBreakdown.describe()` already produces a human-readable combo string (e.g. "Full House — 280 pts"); we just need to animate it in rather than stamping it.

## Goals / Non-Goals

**Goals:**
- Locked dice flash gold briefly to draw the eye to the scoring set.
- Combo label scales in from 0 over ~0.2 s.
- Throw score ticks from 0 to final over ~0.8 s (ease-out).
- Round total ticks up immediately after throw score settles.
- THROW button stays disabled for the full cascade duration.
- Cascade can be triggered headlessly (skipped instantly) for the balance sim / GUT tests.

**Non-Goals:**
- Audio (M3).
- Screen shake / particle effects (separate juice-pass change).
- Per-combo visual differentiation (jackpot flash etc.) — M3 polish.
- Charm-specific cascade steps — deferred until charm framework exists.

## Decisions

### ScoreCascade as a standalone RefCounted
The cascade is a multi-step async sequence (highlight → label pop → score tick → total tick). Embedding this state in `throw_scene.gd` would balloon `_on_resolved()`. A small `ScoreCascade` RefCounted owns the `Tween` and emits `finished` when done; the scene connects to it and re-enables the button there. This keeps the scene thin and lets us unit-test timing in isolation.

*Alternative considered:* inline Tween chain in `throw_scene.gd`. Rejected — harder to test and mixes animation state into gameplay scene.

### Tween for all animation
Godot's `Tween` handles the tick-up (interpolating an int display value), die flash (modulating `albedo_color`), and label scale in a single API. No `_process` frame counting, no wall-clock dependency — complies with the delta-accumulation law.

### Die highlight via DiceTumbler flash method
Rather than reaching into the 3D material directly from the scene, we add `flash_die(index)` to `DiceTumbler` (and implement in `Viewport3DDiceTumbler`). This keeps the renderer boundary intact. The flash tweens `albedo_color` to gold → back to `COLOR_LOCKED` green for already-locked dice, so the highlight reads as "this die scored."

### Headless / test skip
`ScoreCascade` exposes `skip()` which kills the tween and emits `finished` immediately. GUT smoke tests call `skip()` right after triggering resolution so they don't have to wait for animation timers.

### Tick-up interpolation
`Tween.tween_method` with a lambda that sets the label text — interpolates a float, rounds to int for display. Duration 0.8 s, `TRANS_QUAD / EASE_OUT`. Round total uses the same approach but starts only after throw score finishes.

## Risks / Trade-offs

- **Scene freed mid-cascade** → Tween is owned by the scene node (created via `create_tween()`), so it dies automatically with the scene. `ScoreCascade` holds a weak reference to the scene's labels; if the node is gone before `finished` fires, the cascade just stops silently. No crash risk.
- **Very fast throws back-to-back** → User can't press THROW during cascade (button disabled), so the cascade always completes before the next throw starts. No interleaving possible.
- **Long cascade feels slow on re-plays** → 0.8 s is tunable via `ScoreConfig` (already a Resource). We expose `cascade_duration_s: float = 0.8` there so playtest feedback can shorten it without a code change.
