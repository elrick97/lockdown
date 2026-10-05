## Why

Playtesters immediately asked "are there upgrades between antes?" — the game has no answer yet. The shop is the strategic breathing room between antes (PRD §3.1) and is the primary content-unlock surface that makes Lockdown feel like a roguelike rather than a score-attack game. It must exist in skeleton form before the charm framework can be wired in.

**Design pillars served:** Collect & unlock (#5), Readable depth (#3).

## What Changes

- New `ShopScene` (`scenes/shop/shop_scene.tscn` + `.gd`) displayed between antes.
- New `GoldLedger` (`scripts/gold_ledger.gd`) — pure headless resource tracking gold: base award, leftover-throw bonus, interest, spend/buy operations.
- New `ShopOffer` resource (`scripts/shop_offer.gd`) — data container for one purchasable slot: label, cost, type (`CHARM_STUB` / `DICE_STUB` / `SKIP`).
- New `ShopConfig` resource (`scripts/shop_config.gd`) — tunables: base gold per ante, gold per leftover throw, interest rate, re-roll cost, max slots.
- `RunScene` (or `Main` scene, TBD) wires throw loop → shop → next ante navigation; currently the game has no persistent run coordinator, so a minimal `RunCoordinator` node is added to own the ante/shop transition state.
- Shop UI: 3 offer cards (label + cost + BUY button), gold display, RE-ROLL button (costs 1g), CONTINUE button (proceeds to next ante).
- No real charm or dice effects — stubs only. Purchasing a CHARM_STUB or DICE_STUB deducts gold and logs "purchased X" to status label; effect hooks come in `add-charm-framework`.

## Capabilities

### New Capabilities
- `gold-economy`: gold ledger — earn, interest, spend, per-run lifecycle.
- `shop-scene`: shop UI layout, offer cards, re-roll, buy, continue flow.

### Modified Capabilities
- `ante-arc`: run coordinator must advance the ante after CONTINUE is pressed (the existing `AnteArc` logic is unchanged, but it now lives inside a persistent `RunCoordinator` rather than being owned by `ThrowScene` directly).

## Impact

- `scenes/throw/throw_scene.gd` — emits a new `ante_cleared` signal (or delegates to `RunCoordinator`) instead of re-enabling the THROW button directly on ante advance; `RunCoordinator` decides whether to show the shop or advance directly.
- New files: `scenes/shop/shop_scene.tscn`, `scripts/shop_scene.gd`, `scripts/gold_ledger.gd`, `scripts/shop_offer.gd`, `scripts/shop_config.gd`, `scripts/run_coordinator.gd`.
- `resources/shop_config.tres` — default tunables.
- `project.godot` — main scene stays `throw_scene.tscn` for now; `RunCoordinator` is an autoload or injected node (decision in design).
- No changes to `ScoringEngine`, `ThrowController`, `RoundState`, `AnteArc` logic.

## Non-goals

- Real charm effects (add-charm-framework).
- Shop re-roll consuming a separate RNG stream (shop offers are hardcoded stubs; real seeded shop generation comes with charm framework).
- Interest cap / gold cap enforcement beyond a simple clamp (tune in balance pass).
- Shop animations or card flip effects (M3 polish).
- Risk round or Boss round variants (M1 content, after this plumbing lands).
