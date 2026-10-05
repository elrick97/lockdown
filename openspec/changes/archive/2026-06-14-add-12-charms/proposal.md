## Why

The charm framework shipped in `add-charm-framework` with 3 proof-of-concept charms (Quick Draw, Loaded, Snake Charmer). The M1 vertical-slice gate requires 12 charms — enough variety to let a first-time player discover a build identity across a single run. Without them the shop is a stub and the roguelike upgrade loop doesn't land.

## What Changes

- Add 9 new `CharmEffect` GDScript files under `scripts/charms/`, covering all four build archetypes from PRD §4.1 (speed, slow, value, combo).
- Add 9 matching `.tres` resource files under `resources/charms/` with `display_name`, `description`, and `cost` set.
- Add the three proof charms (Quick Draw, Loaded, Snake Charmer) plus all 9 new charms to a new `charm-catalog` living spec that records each charm's tunable values.
- Update `ShopScene._build_offer_pool()` to draw from all 12 charm resources (currently hard-coded to 3 paths).
- GUT headless tests for each new charm's `on_score` logic.
- Note: the headless balance sim (TASKS.md M2) does not yet exist; manual playtest covers balance risk for this batch.

**Non-goals:**
- No new hook plumbing (on_throw / on_window / on_lock effects that alter game state are M2+).
- No new dice materials, boss modifiers, or UI changes.
- No balance sim implementation (that is `add-balance-sim`, M2 gate).

## Capabilities

### New Capabilities
- `charm-catalog`: Living record of all M1 charms — name, effect summary, cost, and tunable values — so balance changes are spec deltas, not silent code edits.

### Modified Capabilities
- `shop-scene`: `_build_offer_pool()` source list expands from 3 paths to 12; no behavior change beyond pool size.

## Impact

- New files: 9 × `scripts/charms/charm_*.gd`, 9 × `resources/charms/*.tres`
- Modified: `scripts/shop_scene.gd` (extend `_CHARM_PATHS` constant)
- New tests: `tests/test_charm_catalog.gd`
- Design pillars served: **collect & unlock** (richer shop variety), **jackpot payoff** (High Roller / Collector enable explosive scoring moments), **flow under pressure** (speed/slow archetype tension reinforces the core lock-window decision)
