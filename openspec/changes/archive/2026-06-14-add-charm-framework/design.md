## Context

The scoring engine and throw controller currently know nothing about charms — `Charm Mult` is documented as "0 in M0" in the combo-scoring spec. The shop offers stub objects with no gameplay effect. This design wires the hook system described in PRD §6 ("data-driven content") so that charm `.tres` files can modify score and throw behaviour without touching engine scripts. Three proof charms validate the pattern before the full 12-charm batch.

## Goals / Non-Goals

**Goals:**
- `CharmEffect` as a Godot `Resource` base class with four overrideable hooks
- `CharmContext` snapshot passed to all hooks — read-only engine state
- `ScoreBreakdown` gains two charm-writable fields; engine applies them once all hooks fire
- `ThrowController` fires `on_throw`, `on_window`, `on_lock` at the right state transitions
- `ScoringEngine.score()` fires `on_score` hooks before computing the final total
- `CharmInventory` (max 5) owned by `RunCoordinator`; shop buys add to it
- Shop loads real `CharmEffect` resources from a hard-coded pool (3 charms)
- All logic headless-safe; new GUT tests cover hook dispatch and the 3 proof charms

**Non-Goals:**
- Charm UI art, tooltips, collection journal, unlock progression
- Boss interactions with charms, Steady Mode charm interaction
- Glass/Echo material cross-hooks
- Dynamic pool scanning (the pool is a preloaded array for now)
- Charm removal or sell-back mechanic

## Decisions

### 1. CharmEffect extends Resource (not Node)

`CharmEffect` is a `Resource` subclass. Each charm is a GDScript that extends `CharmEffect`, and its `.tres` is a saved instance of that script. Loading `preload("res://resources/charms/quick_draw.tres")` gives you a live, executable object with the hooks already bound.

**Alternative considered:** Separate data Resource (`CharmDef`) + behavior class. Rejected: doubles the file count per charm with no benefit. The hook methods are the data — there is no data/behaviour split worth making.

### 2. CharmContext is an immutable snapshot (RefCounted)

Built fresh before each hook dispatch call. Fields:
```
var locked_faces: Array[int]     # copy, not live reference
var locked_windows: Array[int]   # which window each die was locked in (0 = not locked)
var window_times: Array[float]   # per-window remaining times so far
var current_window: int          # 0 during on_throw; 1-3 during on_window/on_lock
var die_index: int               # -1 unless on_lock
var round_total: int             # score accumulated so far this round
var throw_number: int
```

Charms read from context; they cannot mutate it. This prevents charms from corrupting engine state and keeps them headless-safe by avoiding live node references.

**Alternative considered:** pass live `ThrowController` reference. Rejected: breaks headless tests and violates the "keep logic in plain scripts" architectural law.

### 3. on_score mutates ScoreBreakdown in-place

`ScoreBreakdown` gets two new fields: `charm_chips: int = 0` and `charm_mult: float = 0.0`. Each `on_score(breakdown, ctx)` hook adds to those fields. The engine reads them once, after all hooks have fired, to compute the final score.

Order: charms apply in slot order (index 0 → 4). This is deterministic and matches the display order in the charm row.

**Alternative considered:** hooks return delta structs and the engine sums them. More composable in theory but adds allocations per hook call with no benefit at this scale (max 5 charms).

### 4. on_throw / on_window / on_lock return void for now

The 3 proof charms only need `on_score`. The other hooks fire but their results are discarded. Future charms that need side-effects (e.g., Magnet's "pull matching faces to lock") will extend the context's return value or use a separate signal — that's deferred to the charm that needs it.

### 5. Charm pool is a hard-coded preload array in ShopScene

For 3 charms, `_build_offer_pool()` returns a hardcoded `Array[CharmEffect]`. Before `_refresh_offers()`, the pool is shuffled via `RngService` and the first 3 entries become the offer slots. This keeps the shop wired without a full content-catalogue system.

**Alternative considered:** scan `res://resources/charms/` at runtime with `DirAccess`. Rejected: order is non-deterministic and breaks seeded runs. The explicit pool array IS the catalogue for now.

### 6. CharmInventory is a plain RefCounted, owned by RunCoordinator

```
var _slots: Array[CharmEffect] = []
const MAX_SLOTS := 5

func add_charm(c: CharmEffect) -> bool  # returns false if full
func iter_charms() -> Array[CharmEffect]  # defensive copy
func is_full() -> bool
```

RunCoordinator resets it in `start_run()`. ThrowController and ScoringEngine receive it by reference when constructed per throw.

## Risks / Trade-offs

**[Risk] Charm ordering affects game balance** → Mitigation: define slot order as display order; document it in the spec. Balance sim (add-12-charms) will catch degenerate stacking.

**[Risk] on_score hooks can inspect the fully-computed breakdown** (pips, combo_mult already set) and write unbounded charm_mult → Mitigation: no cap in M1; the balance sim gates this before the full 12-charm batch lands.

**[Risk] Hard-coded pool doesn't scale past ~6 charms** → Mitigation: for M1 (12 charms) the pool remains explicit. A proper catalogue with `CharmCatalogue` resource is scoped to M2.

**[Risk] RngService shop shuffle consumes entropy from the main stream** → Mitigation: add a dedicated `shop` stream to RngService (separate from `dice` and `core`), so shop offers don't affect throw outcomes.
