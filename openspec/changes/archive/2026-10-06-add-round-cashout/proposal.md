## Why

UI/UX audit finding D3: winning a round cuts straight from "TARGET HIT!" to the shop. Where the gold came from is never shown: base 4g, +1g per spare throw, 25% interest (capped at 40). So the economy, and the reason to finish fast with throws left, stays invisible. Balatro's cash-out screen itemises every dollar before the shop, and it doubles as a pacing breather. PRD trace: §2 *Jackpot payoff*, *Readable depth*; §4.3 economy.

## What Changes

- **ROUND CLEARED panel:** after TARGET HIT, a panel opens on the throw screen. It reuses the end-panel card, stamp and count-up. Itemised lines tick in one by one:
  - "Round reward" +4g;
  - "Spare throws ×N" +Ng;
  - "Interest (25% of X, max 40)" +Yg.

  Then the new gold total stamps in.
- **CONTINUE:** a primary button opens the shop. Tap-to-skip jumps to the final values.
- **Risk skip:** the same panel shows "Skipped risk round" +3g, plus interest.
- **Interest timing:** interest is still applied once per shop visit (gold-economy spec). The panel shows the exact amount the shop will hold, computed from the same `GoldLedger` and `ShopConfig` methods. Gold math is unchanged.

## Capabilities

### Modified Capabilities
- `run-flow`: adds the round-cleared panel between the throw screen and the shop.
- `gold-economy`: the income breakdown is presented (no formula change).

## Impact

- `throw_scene.gd` (panel), `run_coordinator.gd` (ante-clear hands off after CONTINUE instead of instantly), and a small `GoldLedger` read-only breakdown helper.
- Tests: the itemised lines sum to the gold the shop opens with, for normal clears, spare throws, interest, the cap, and the risk skip.
