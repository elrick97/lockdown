# Proposal: add-juice-pass

## What
First juice pass for M1: lock haptics (vibrate on die lock), combo screen shake (scene shake when combos land in ScoreCascade), and audio stub infrastructure (AudioStreamPlayer in ThrowScene, wired up so art can drop-in audio assets without code changes).

## Why
PRD §2 design pillar — Jackpot Payoff: "every lock and score needs to feel satisfying before we validate with strangers." TASKS.md M1 Feel & Presentation: "First juice pass: score tick-up audio w/ rising pitch, lock haptics, combo screen shake." The cascade animation is already in; haptics and shake are code-only additions that immediately lift feel without waiting on audio assets.

## Scope

### In
- **Lock haptics**: `Input.vibrate_handheld(30)` in `_on_die_locked()` in ThrowScene
- **Combo screen shake**: Tween-based position offset on ThrowScene root during ScoreCascade combo flash (amplitude: 8px, duration: 0.25s, decaying sine)
- **Audio stub**: AudioStreamPlayer nodes wired as exports in ThrowScene (`_sfx_lock`, `_sfx_combo`); play() calls present but no-op when stream is null; art/audio drops `.wav`/`.ogg` files into `assets/audio/` and assigns them in the `.tscn` without code changes

### Out
- Rising-pitch score tick (needs audio file + pitch shift — added as stub for now)
- Charm purchase SFX (M2)
- Boss intro SFX (M2)

## PRD trace
PRD §2: Jackpot Payoff pillar. PRD §8.2: "Sound design: functional (no fluff), mobile-mixed, punchy lock + cascade hits."

## Risks
- `Input.vibrate_handheld` is Android-only; no-ops silently on other platforms. No guard needed.
- Screen shake using scene-root position shifts might interact with `_apply_layout()` which sets Control anchors. Use a child `_shake_pivot: Node2D` parent instead, or Tween a separate `screen_shake` Vector2 property applied in `_process`.
