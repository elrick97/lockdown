## 1. Economy

- [x] 1.1 `on_ante_cleared` / `on_risk_skipped` build itemised lines, apply interest once, emit `cashout_ready`; `go_to_shop()`
- [x] 1.2 Risk skip applies interest per the gold-economy spec (was missing)

## 2. Panel

- [x] 2.1 Round-cleared panel: stamped title, fading lines with signed amounts, GOLD count-up, CONTINUE

## 3. Verification

- [x] 3.1 Tests: lines sum to the new gold across cases incl. the cap; named sources; skip with interest; panel shown, THROW hidden, CONTINUE wired, total counts up
- [x] 3.2 GUT green; playthrough (skip → cash-out → shop) with screenshot
