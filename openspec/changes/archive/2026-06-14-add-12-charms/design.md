## Context

The `add-charm-framework` change shipped a complete `CharmEffect` hook system and 3 proof-of-concept charms. `ShopScene` draws from a hard-coded 3-path constant. Nine additional charms are needed to hit the M1 "12 for vertical slice" gate from PRD §4.1. The framework requires no changes — all new charms are pure content implemented as GDScript + `.tres` pairs.

## Goals / Non-Goals

**Goals:**
- 9 new `CharmEffect` subclasses covering speed, slow, value, and combo archetypes
- Each charm is headless-testable and `.tres`-loadable
- `ShopScene` pool grows to 12 without structural changes to the scene
- All effects implemented via `on_score` only (no game-state mutation)

**Non-Goals:**
- No new hook types or CharmContext fields (see risk #1)
- No balance sim (deferred to `add-balance-sim`, M2 gate)
- No UI changes to the shop or charm display
- No new dice materials, boss modifiers, or engine changes

## Decisions

### 1. All 9 charms use `on_score` only

All new charms are pure scoring modifiers. The `on_throw`, `on_window`, and `on_lock` hooks are fire-and-forget in M1 (they cannot mutate lock state or faces), so archetypes that could theoretically hook in-play (e.g. Magnet triggering auto-locks) are deferred.

**Alternative considered:** implement a context-mutation hook (`on_lock` returns a list of additional dice to lock). Rejected — would require breaking the current fire-and-forget contract and isn't needed for the 12-charm target.

### 2. Patient Zero uses fixed +5 Chips per W3 die (not face-value doubling)

The PRD describes Patient Zero as "dice locked in Window 3 score double Pips." True face-value doubling requires pairing each die's face with its window — but `CharmContext` currently only provides `locked_faces` in lock order and `locked_windows` in slot order, with no shared index (`locked_order` is not exposed). Matching them requires either adding `locked_order` or `faces_by_slot` to `CharmContext`.

This change explicitly defers that CharmContext extension. Patient Zero ships as "+5 Charm Chips per die locked in Window 3" — mechanically in the same direction (slow-build reward) at lower implementation cost. The delta spec documents the intended final rule; a later change can refine it when CharmContext is extended.

### 3. Combo charms inspect `breakdown.combos[i].name` (string), not `.type` (int)

The `ScoringConfig.ComboType` enum int values are an implementation detail that could shift. Checking `.name` strings ("Quad", "Large Straight") is stable against enum renumbering, explicit in code, and matches what the proof charms already do.

### 4. ShopScene pool is a static constant array, extended in-place

`_CHARM_PATHS` in `shop_scene.gd` grows from 3 to 12 entries. No dynamic resource discovery. This keeps the pool deterministic and avoids silent pool growth when charm files are added for other reasons (tests, editor experiments).

### 5. Balance: GUT tests + manual playtest; no headless sim

The M2 balance sim (`add-balance-sim`) doesn't exist yet. For this batch, balance risk is mitigated by:
- GUT headless unit tests for each charm's edge cases
- Manual playtest pass on device verifying no charm trivially wins every throw

## Risks / Trade-offs

**[Risk] Patient Zero is weaker than the final design** → Acceptable for the M1 slice; document the intended final rule in the spec so the gap is visible.

**[Risk] Collector/Straight Edge may rarely activate on standard 2-die draws** → Adjust cost downward post-playtest; costs are spec tunables, not hardcoded.

**[Risk] No balance sim means degenerate stacks (Collector + High Roller + Loaded) may be undetected** → Mitigated by manual multi-charm playtest before the M1 gate review. Flag for the balance sim backlog.

## The 9 New Charms

All use `on_score`. Tunable values in parentheses are current defaults; adjust via balance sim in M2.

| # | Name | Archetype | Effect | Cost |
|---|------|-----------|--------|------|
| 4 | Hair Trigger | Speed | +5 Charm Chips per die locked in Window 1 | 4 |
| 5 | Adrenaline | Speed | If ≥3 dice locked in W1, +1 Charm Mult | 4 |
| 6 | Patient Zero | Slow | +5 Charm Chips per die locked in Window 3 | 4 |
| 7 | Ice Cold | Slow | If zero dice locked in W1, +3 Charm Mult | 6 |
| 8 | Big Bucks | Value | +3 Charm Chips per locked 5 or 6 | 3 |
| 9 | Precision | Value | If all locked dice show the same face, +2 Charm Mult | 6 |
| 10 | Collector | Combo | +1 Charm Mult per distinct face value in the locked set | 5 |
| 11 | High Roller | Combo | If winning combo is Quad or Quint+, +60 Charm Chips | 7 |
| 12 | Straight Edge | Combo | If winning partition contains a Straight, +3 Charm Mult | 5 |
