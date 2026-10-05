## Why

Playtesters immediately asked "how does the count add up?" after their first throw — the score appears as a static number with no sense of drama. The jackpot-payoff pillar requires scoring to escalate visibly; right now it doesn't. This is the fastest M1 feel win available because the scoring engine is already correct and the presentation just needs animation layered on top.

## What Changes

- After throw resolution, locked dice flash/highlight in sequence to draw the eye to what's scoring.
- A combo label (e.g. "FULL HOUSE ×8") pops in with a scale-in tween before the number starts moving.
- The throw score ticks up from 0 to its final value over ~0.8 s using a fast ease-out curve.
- The round total ticks up immediately after the throw score settles.
- The THROW button stays disabled for the duration of the cascade so the player sees the payoff before the next throw is available.
- No audio (M3). No screen shake (separate juice-pass change in M1).

## Capabilities

### New Capabilities
- `score-cascade`: animated score reveal sequence that plays between throw resolution and the next-throw prompt — highlights locked dice, pops in combo label, ticks up throw score then round total.

### Modified Capabilities
- `throw-loop`: minor behavioral addendum — the THROW button must remain disabled until the cascade animation completes (currently it re-enables as soon as score is assigned).

## Impact

- `scenes/throw/throw_scene.gd` — `_on_resolved()` drives the cascade instead of setting labels immediately; button re-enable moves to the end of the cascade.
- `scripts/score_cascade.gd` — new `RefCounted` that owns the tween sequence, emits `finished` when done; keeps logic out of the scene.
- `scenes/throw/throw_scene.tscn` — no structural changes needed; existing labels are reused.
- No changes to `ScoringEngine`, `ThrowController`, `RoundState`, or `AnteArc`.
