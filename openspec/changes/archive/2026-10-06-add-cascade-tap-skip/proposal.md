## Why

The Chips × Mult cascade from `add-score-feedback` takes 2–4 s on big hands, and THROW waits for it. That is great the first time and slow the tenth. Balatro lets you speed through. The `add-score-feedback` design left a tap-to-skip input for later; this change adds it. PRD trace: §2 *Flow under pressure* (keep the loop moving), §5 juice.

**Pillars served:** *Flow under pressure*: experienced players keep the pace. *Jackpot payoff* is kept by default, because the full cascade still plays unless you tap.

## What Changes

- **Tap to skip:** a tap anywhere off the buttons during the cascade calls `ScoreCascade.skip()`. It lands on the exact final state (plaques, score, total, target bar) and re-enables THROW at once.
- **Grace period:** taps in the first `skip_grace_s` (0.35 s) are ignored, so the tap that locks the last die never skips its own payoff.
- **Hint:** a muted "TAP TO SKIP" shows in the empty trinket band while the cascade plays.
- **Cascade API:** `ScoreCascade` gains `is_playing()` and `elapsed_s()`.

## Capabilities

### Modified Capabilities
- `score-cascade`: adds tap to skip.

## Impact

- `score_cascade.gd`, `feedback_config.gd` (`skip_grace_s`), the throw scene's input handling and hint.
- No scoring change. Skipping reuses the tested `skip()` path.
