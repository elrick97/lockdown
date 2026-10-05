## 1. Trinket base class

- [x] 1.1 Create `scripts/trinket.gd` — `Trinket extends Resource` with display_name, description, cost, `activate(controller) -> void` (no-op base)
- [x] 1.2 Create `scripts/trinkets/trinket_re_tumble.gd` — calls `controller.force_reroll_unlocked()`
- [x] 1.3 Create `scripts/trinkets/trinket_freeze_timer.gd` — calls `controller.freeze_window(2.0)`
- [x] 1.4 Create `resources/trinkets/re_tumble.tres` — cost=3
- [x] 1.5 Create `resources/trinkets/freeze_timer.tres` — cost=4

## 2. TrinketInventory

- [x] 2.1 Create `scripts/trinket_inventory.gd` — MAX_SLOTS=2, add_trinket, consume, iter_trinkets, is_full

## 3. ThrowController additions

- [x] 3.1 Add `force_reroll_unlocked()` — re-rolls all non-locked dice (same logic as `_begin_reroll` but stays in LOCK_WINDOW state)
- [x] 3.2 Add `freeze_window(duration: float)` — subtracts duration from _accumulated, clamped to 0

## 4. RunCoordinator

- [x] 4.1 Add `var trinket_inventory: TrinketInventory`; init in `start_run()`

## 5. ThrowScene

- [x] 5.1 Build trinket button row (HBoxContainer, up to 2 buttons) in `_ready()`; hide until LOCK_WINDOW
- [x] 5.2 Show buttons during LOCK_WINDOW, hide otherwise
- [x] 5.3 On trinket button press: activate, consume from inventory, update buttons

## 6. ShopScene

- [x] 6.1 Add `_TRINKET_PATHS` constant (re_tumble, freeze_timer); include in mixed offer pool
- [x] 6.2 Buying a trinket: `RunCoordinator.trinket_inventory.add_trinket(trinket)`
- [x] 6.3 Trinket-full check blocks trinket buy when TrinketInventory.is_full()

## 7. Tests

- [x] 7.1 TrinketInventory cap test (add 3, third returns false)
- [x] 7.2 freeze_window extends window (controller headless test)

## 8. Verify on device

- [ ] 8.1 Build + deploy; buy Re-Tumble, activate mid-window — dice re-roll; buy Freeze Timer, activate — window visibly extends
