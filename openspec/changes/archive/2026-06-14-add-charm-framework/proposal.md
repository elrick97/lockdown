## Why

The shop exists but offers only stubs; players can spend gold on nothing real yet. Before the 12 launch charms can be added as data, the engine needs a hook system that lets charm `.tres` files modify scoring and throw behaviour without touching the engine scripts. This is the prerequisite gating the rest of M1's content pipeline.

## What Changes

- New `CharmEffect` base `Resource` class with four override-able hooks: `on_throw`, `on_window`, `on_lock`, `on_score`. Each receives a `CharmContext` carrying read-only run state.
- New `CharmContext` `RefCounted` — snapshot of game state at hook call time (locked faces array, window index, window time remaining, round total, throw number). Charms read it; they never mutate it.
- `ScoreBreakdown` gains two charm-writable fields: `charm_chips: int = 0` and `charm_mult: float = 1.0`. The final score formula becomes `(pips + bonus_chips + charm_chips) × (combo_mult + charm_mult) × heat`.
- `ScoringEngine.score()` accepts an optional `CharmInventory` parameter and calls each charm's `on_score` hook before computing the final total.
- `ThrowController` calls `on_throw` at the start of each throw, `on_window` when a window opens, and `on_lock` when a die is locked.
- New `CharmInventory` `RefCounted` — ordered list of up to 5 `CharmEffect` slots, owned by `RunCoordinator`. Exposes `add_charm`, `remove_charm`, `iter_charms`.
- `ShopScene` loads real `CharmEffect` resources from `res://resources/charms/` instead of type stubs. Offers display `display_name`, `description`, and `cost` from the resource.
- 3 proof-of-concept charms shipped as `.tres` files: **Quick Draw** (×2 Mult if all locks in Window 1), **Loaded** (6s count as 12 Pips), **Snake Charmer** (pair of 1s gives ×4 Mult instead of standard scoring).

## Capabilities

### New Capabilities
- `charm-effect`: `CharmEffect` base resource, `CharmContext` struct, `CharmInventory` container, and the hook dispatch contract

### Modified Capabilities
- `combo-scoring`: scoring formula gains `charm_chips` and `charm_mult` fields; `ScoringEngine.score()` takes optional `CharmInventory` and fires `on_score` hooks
- `throw-loop`: `ThrowController` fires `on_throw`, `on_window`, `on_lock` charm hooks at the appropriate state transitions
- `shop-scene`: offer pool sources real `CharmEffect` resources; buying a charm adds it to `RunCoordinator.inventory`

## Impact

- `scripts/charm_effect.gd` — new (base Resource)
- `scripts/charm_context.gd` — new (RefCounted snapshot)
- `scripts/charm_inventory.gd` — new (RefCounted list, max 5)
- `scripts/score_breakdown.gd` — add `charm_chips` and `charm_mult` fields
- `scripts/scoring_engine.gd` — extend `score()` to apply charm hooks
- `scripts/throw_controller.gd` — fire hook calls at three state transitions
- `scripts/run_coordinator.gd` — add `inventory: CharmInventory`, reset in `start_run()`
- `scripts/shop_scene.gd` — swap stub pool for real resource loading
- `resources/charms/quick_draw.tres`, `loaded.tres`, `snake_charmer.tres` — 3 proof charms
- `scripts/charms/charm_quick_draw.gd`, `charm_loaded.gd`, `charm_snake_charmer.gd` — charm scripts

**Non-goals:** charm UI art, charm collection journal, unlock system, boss interactions with charms, Glass/Echo material interactions. Those come later.

**Pillars served:** Jackpot payoff (charms create multiplier explosions), Readable depth (discovery of synergies), Collect & unlock (charm slots visible in shop).
