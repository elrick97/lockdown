## Context

`ThrowController.freeze_window(duration)` does `_accumulated = maxf(0.0, _accumulated - duration)`. Spark calls it with 0.5 s and Freeze Timer with 2.0 s, so neither can raise the remaining time above the window's duration. The specs describe the additions without the cap.

## Decisions

### D1: Spec-only clarification
The owner kept the cap (2026-10-05). The Spark and Freeze Timer requirements now state it, each with an early-press scenario. No code change.

### D2: Pin it with tests
Two headless tests assert the capped values, so a later change to `freeze_window` can't drop the cap silently.

## Risks / Trade-offs

- None for behavior: the wording now matches what players already get.
