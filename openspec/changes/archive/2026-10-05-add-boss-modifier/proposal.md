# Proposal: add-boss-modifier

## What
Introduce round-type awareness (Open / Risk / Boss) to the ante arc. Designate the last ante as the Boss round: show a "BOSS ROUND" label and halve the lock-window duration for that ante.

## Why
PRD §3.1 specifies 3 round types per ante. M1 gate requires at least 1 boss modifier. Halved lock windows create meaningful pressure escalation on the final ante of the vertical slice.

## Capabilities affected
- **MODIFIED** `ante-arc` spec — adds round-name labels per ante and boss modifier parameter
- **MODIFIED** `throw-loop` spec — boss round applies halved window duration

## Non-goals
- Full 6-ante × 3-round structure (M2)
- Additional boss modifiers beyond halved windows (M2 has 8)
- Visual boss intro animation
