## Context

`ThrowController` ends a window early through `_end_window_all_locked()` when `lock_die()` finds `not locked.has(false)`. Shattered Glass dice stay `locked = false` forever and `lock_die()` rejects them (since the `add-dice-materials` verification fix), so with any shattered die that test never passes. After a window expires, `_begin_reroll()` shatters the unlocked Glass dice and always enters `REROLL`, even when no live unlocked die remains.

## Goals / Non-Goals

**Goals:** dead slots never hold a throw open; the speed reward works with Glass in the tray; no empty windows; Heat unchanged for the nothing-left-to-lock case (owner decision: no credit).

**Non-goals:** Heat formula or tunables, Glass rules, presentation.

## Decisions

### D1: One predicate, "all done"
Add `_all_done() -> bool`: every slot is `locked[i] or _shattered[i]`. `lock_die()` calls it instead of `not locked.has(false)`. A single predicate keeps the two paths (lock and re-roll) consistent.

### D2: Lock path keeps the existing credit rule
When the last live die is locked, `_end_window_all_locked()` runs unchanged: remaining time for the current window, full duration for later windows. This is the existing rule applied correctly, not a new one.

### D3: Re-roll path resolves with no credit
In `_begin_reroll()`, after shattering, if `_all_done()` then record 0 for windows `window_index+1..3` and call `_resolve()` instead of entering `REROLL`. The expired window already recorded its own remaining time (0) in `_end_window_by_expiry()`. *Alternative:* reuse `_end_window_all_locked()`. Rejected because it credits full duration, which the owner ruled out.

### D4: Scene needs no new code path
`ThrowScene` already handles `resolved` from any state. The re-roll path emits `resolved` without `reroll_started`, so no tumble starts and the cascade plays as usual. The playthrough checks this end to end.

## Risks / Trade-offs

- **Heat rises for throws where the player locks every live die fast with dead slots present** (×1.0 → ×1.3 in case C). This is intended: it matches the same play without Glass.
- **No balance sim yet** → the proposal's hand-computed cases are asserted in headless tests instead.
