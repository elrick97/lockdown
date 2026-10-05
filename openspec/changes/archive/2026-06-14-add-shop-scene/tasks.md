## 1. Headless data layer

- [x] 1.1 Create `scripts/shop_config.gd` (`Resource`) — exports: `base_gold_per_ante: int = 4`, `gold_per_leftover_throw: int = 1`, `interest_rate: float = 0.25`, `max_gold: int = 40`, `reroll_cost: int = 1`, `offer_slots: int = 3`
- [x] 1.2 Create `resources/shop_config.tres` with default values
- [x] 1.3 Create `scripts/gold_ledger.gd` (`RefCounted`) — `gold: int`, `earn(amount)`, `apply_interest(config)`, `can_afford(cost) -> bool`, `spend(cost) -> bool` (returns false if insufficient)
- [x] 1.4 Create `scripts/shop_offer.gd` (`RefCounted`) — `enum Type { CHARM_STUB, DICE_STUB, SKIP }`, fields: `type`, `label: String`, `cost: int`, `sold: bool`

## 2. RunCoordinator autoload

- [x] 2.1 Create `scripts/run_coordinator.gd` (`Node`) — fields: `arc: AnteArc`, `ledger: GoldLedger`, `config: AnteConfig`, `shop_config: ShopConfig`, `_throws_left: int`; signals: `run_started`
- [x] 2.2 Implement `start_run()` — creates fresh `AnteArc` and `GoldLedger`, connects `arc.run_won` / `arc.run_lost`
- [x] 2.3 Implement `on_ante_cleared(throws_left: int)` — calls `ledger.earn(...)`, `ledger.apply_interest(shop_config)`, then `get_tree().change_scene_to_file("res://scenes/shop/shop_scene.tscn")`
- [x] 2.4 Implement `on_shop_continued()` — calls `get_tree().change_scene_to_file("res://scenes/throw/throw_scene.tscn")`
- [x] 2.5 Register `RunCoordinator` as autoload in `project.godot` (`res://scripts/run_coordinator.gd`, name `RunCoordinator`)

## 3. ThrowScene wiring changes

- [x] 3.1 Remove `AnteArc` construction from `ThrowScene._ready()`; instead read `RunCoordinator.arc` (call `RunCoordinator.start_run()` only if `arc == null`, i.e. fresh launch)
- [x] 3.2 Replace `_on_ante_advanced()` body: emit `ante_cleared(throws_left)` signal and disable THROW button; remove the direct label update and button re-enable that was there
- [x] 3.3 Add `signal ante_cleared(throws_left: int)` to `ThrowScene`; connect it to `RunCoordinator.on_ante_cleared` in `_ready()`
- [x] 3.4 Update smoke tests: call `RunCoordinator.start_run()` in `before_each` so the autoload is in a clean state; verify full-run test still passes

## 4. ShopScene

- [x] 4.1 Create `scenes/shop/` directory; create `scenes/shop/shop_scene.tscn` with nodes: root `Control`, `GoldLabel`, `OfferContainer` (VBoxContainer with 3 `OfferCard` sub-scenes or inline HBoxes), `RerollButton`, `ContinueButton`, `StatusLabel`
- [x] 4.2 Create `scripts/shop_scene.gd` — `_ready()` reads `RunCoordinator.ledger` and `RunCoordinator.shop_config`, calls `_apply_layout()` and `_refresh_offers()`
- [x] 4.3 Implement `_apply_layout()` — sets all Control anchors in code (Android export safety pattern)
- [x] 4.4 Implement `_refresh_offers()` — builds 3 stub `ShopOffer` objects, renders each card (label + cost + BUY button), disables BUY if `!ledger.can_afford(offer.cost)`, marks sold slots as greyed out
- [x] 4.5 Wire BUY button: calls `ledger.spend(offer.cost)`, marks slot sold, updates gold label, refreshes button states
- [x] 4.6 Wire RE-ROLL button: calls `ledger.spend(reroll_cost)`, calls `_refresh_offers()`, updates gold label; disable when `!ledger.can_afford(reroll_cost)`
- [x] 4.7 Wire CONTINUE button: calls `RunCoordinator.on_shop_continued()`

## 5. Tests

- [x] 5.1 `tests/test_gold_ledger.gd` — headless tests: earn, interest calculation, interest capped at max_gold, spend success, spend failure (insufficient gold), re-roll deduction
- [x] 5.2 Update `tests/test_round_smoke.gd` `before_each` / `_do_throw` to ensure `RunCoordinator.start_run()` is called so arc is initialised; verify full 3-ante run still reaches terminal state

## 6. Verify on device

- [x] 6.1 Build APK, install on Pixel 9 — clear ante 1, confirm shop scene loads with gold displayed and 3 offer cards
- [x] 6.2 Buy one offer, press RE-ROLL, press CONTINUE — confirm gold deducts correctly and throw scene reloads for ante 2
- [x] 6.3 Complete all 3 antes — confirm no shop appears after the final ante and win state is reached
