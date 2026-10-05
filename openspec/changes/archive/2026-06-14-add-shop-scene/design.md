## Context

The game currently has no persistent run coordinator: `ThrowScene` owns `AnteArc` and directly re-enables its own THROW button on ante advance. This worked for M0 (single scene, no navigation), but adding a shop requires a scene transition — something `ThrowScene` cannot drive alone. The core challenge is introducing a run-level coordinator without disrupting the working throw loop or its tests.

## Goals / Non-Goals

**Goals:**
- `RunCoordinator` autoload node owns `AnteArc` and `GoldLedger` for the whole run; `ThrowScene` receives them by injection on entry.
- After an ante clears, `RunCoordinator` transitions to `ShopScene`; after CONTINUE, it transitions back to `ThrowScene` with the next ante target.
- `GoldLedger` is pure headless: earns gold (base + leftover throws + interest), spends on shop purchases, exposes current balance.
- `ShopScene` shows 3 hardcoded stub offers; RE-ROLL refreshes them (costs 1g); BUY deducts gold and marks the slot sold; CONTINUE advances the run.
- All new logic is headless-testable: `GoldLedger` and `RunCoordinator` are plain scripts, no scene dependency.

**Non-Goals:**
- Real charm/dice effects — stubs only, effect hook system is `add-charm-framework`.
- Seeded shop offer generation — offers are hardcoded for now; RNG shop comes with charm framework.
- Shop animations, card flips, gold coin particles — M3.
- Risk / Boss round routing — M1 content after this plumbing.
- Save/resume mid-run — M2.

## Decisions

### RunCoordinator as an Autoload
`RunCoordinator` is registered as an autoload singleton (`res://scripts/run_coordinator.gd`). This avoids passing it through scene instantiation arguments and keeps `ThrowScene` and `ShopScene` decoupled — each calls `RunCoordinator.start_run()` / `RunCoordinator.on_ante_cleared()` / `RunCoordinator.on_shop_continued()`.

*Alternative:* pass coordinator by node path via export vars. Rejected — makes scenes harder to test in isolation and requires wiring on every scene change.

### ThrowScene emits `ante_cleared` signal; RunCoordinator listens
`ThrowScene._on_ante_advanced()` currently re-enables the THROW button for the next ante. Instead it now emits `ante_cleared(gold_earned: int)` and disables the button. `RunCoordinator` catches this, credits gold to `GoldLedger`, then calls `get_tree().change_scene_to_file("res://scenes/shop/shop_scene.tscn")`. On return, `RunCoordinator.pending_target` feeds `ThrowScene` the new ante target.

`run_won` and `run_lost` paths are unaffected — those stay in `ThrowScene` as terminal states (no shop on game-over).

### GoldLedger as a plain RefCounted on RunCoordinator
`GoldLedger` is a `RefCounted` (not a Resource) because it holds mutable run state, not authored data. `RunCoordinator` owns the single instance for the run lifetime. `ShopScene` receives it by reference from `RunCoordinator`.

### Gold formula
`gold_earned = shop_config.base_gold_per_ante + (throws_left * shop_config.gold_per_leftover_throw)`
Interest: `gold += floor(gold * shop_config.interest_rate)` applied once per shop visit, before the player spends. Capped at `shop_config.max_gold` (prevents runaway snowball in M1).

### Offer stubs
Three hardcoded `ShopOffer` objects are generated at shop entry: `{type: CHARM_STUB, label: "Lucky Charm", cost: 3}`, `{type: DICE_STUB, label: "Bone Die", cost: 2}`, `{type: SKIP, label: "Skip (free)", cost: 0}`. RE-ROLL cycles through a second set of stubs (just shuffles the same three). Real offer generation — seeded, weighted, charm-resource-backed — comes in `add-charm-framework`.

### ShopScene layout (code-driven, Android-safe)
Same pattern as `ThrowScene`: all Control anchors set in `_apply_layout()` at runtime to survive the Android export anchor-stripping bug.

## Risks / Trade-offs

- **Autoload init order** → `RunCoordinator` must not reference `RngService` at `_ready` time before `RngService` initialises. Mitigation: `RunCoordinator.start_run()` is called explicitly by `ThrowScene._ready()`, never at autoload init.
- **ThrowScene tests break if RunCoordinator is missing** → smoke tests inject a mock or call `RunCoordinator.start_run()` directly in `before_each`. The autoload is available in-tree during GUT runs, so this should be transparent.
- **Scene change loses ThrowScene state** → intentional; run state lives in `RunCoordinator` (ante, gold), not in the scene. ThrowScene reconstructs from `RunCoordinator` on re-entry.
