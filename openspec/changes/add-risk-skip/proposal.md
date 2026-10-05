# Proposal: add-risk-skip

## What
Add a SKIP button to the Risk round (ante 2). Pressing it earns a small fixed gold reward and advances directly to the Boss round without playing that ante.

## Why
PRD §3.1: "Risk (skippable for reduced reward)". It introduces strategic tension — take the guaranteed gold or gamble for a bigger round-won payout?

## Capabilities affected
- **MODIFIED** `ante-arc` spec — adds skip_reward_gold tunable and skip path
- **MODIFIED** `throw-loop` spec — shows SKIP UI during the risk ante only

## Non-goals
- Multiple risk rounds per ante (M2 full structure)
- Variable or escalating skip rewards
