## 1. Speed charms

- [x] 1.1 Create `scripts/charms/charm_hair_trigger.gd` — extends `CharmEffect`; `on_score`: for each entry in `ctx.locked_windows` equal to 1, `breakdown.charm_chips += 5`
- [x] 1.2 Create `resources/charms/hair_trigger.tres` — `display_name = "Hair Trigger"`, `description = "Each die locked in Window 1 adds +5 Chips."`, `cost = 4`
- [x] 1.3 Create `scripts/charms/charm_adrenaline.gd` — extends `CharmEffect`; `on_score`: count entries in `ctx.locked_windows` equal to 1; if count ≥ 3, `breakdown.charm_mult += 1.0`
- [x] 1.4 Create `resources/charms/adrenaline.tres` — `display_name = "Adrenaline"`, `description = "Lock 3+ dice in Window 1 to score +1 Mult."`, `cost = 4`

## 2. Slow charms

- [x] 2.1 Create `scripts/charms/charm_patient_zero.gd` — extends `CharmEffect`; `on_score`: for each entry in `ctx.locked_windows` equal to 3, `breakdown.charm_chips += 5`
- [x] 2.2 Create `resources/charms/patient_zero.tres` — `display_name = "Patient Zero"`, `description = "Each die locked in Window 3 adds +5 Chips."`, `cost = 4`
- [x] 2.3 Create `scripts/charms/charm_ice_cold.gd` — extends `CharmEffect`; `on_score`: iterate `ctx.locked_windows`; if any entry equals 1, return early; else `breakdown.charm_mult += 3.0`
- [x] 2.4 Create `resources/charms/ice_cold.tres` — `display_name = "Ice Cold"`, `description = "Skip Window 1 entirely to score +3 Mult."`, `cost = 6`

## 3. Value charms

- [x] 3.1 Create `scripts/charms/charm_big_bucks.gd` — extends `CharmEffect`; `on_score`: for each face in `ctx.locked_faces` that equals 5 or 6, `breakdown.charm_chips += 3`
- [x] 3.2 Create `resources/charms/big_bucks.tres` — `display_name = "Big Bucks"`, `description = "Each locked 5 or 6 adds +3 Chips."`, `cost = 3`
- [x] 3.3 Create `scripts/charms/charm_precision.gd` — extends `CharmEffect`; `on_score`: if `ctx.locked_faces` is non-empty and all entries equal the first entry, `breakdown.charm_mult += 2.0`
- [x] 3.4 Create `resources/charms/precision.tres` — `display_name = "Precision"`, `description = "All locked dice on the same face? +2 Mult."`, `cost = 6`

## 4. Combo charms

- [x] 4.1 Create `scripts/charms/charm_collector.gd` — extends `CharmEffect`; `on_score`: count distinct face values in `ctx.locked_faces` using a Dictionary; `breakdown.charm_mult += float(distinct_count)`
- [x] 4.2 Create `resources/charms/collector.tres` — `display_name = "Collector"`, `description = "+1 Mult per distinct face value in your locked set."`, `cost = 5`
- [x] 4.3 Create `scripts/charms/charm_high_roller.gd` — extends `CharmEffect`; `on_score`: if `breakdown.combos` is non-empty and `breakdown.combos[0].name` is `"Quad"` or `"Quint"`, `breakdown.charm_chips += 60`
- [x] 4.4 Create `resources/charms/high_roller.tres` — `display_name = "High Roller"`, `description = "Score a Quad or Quint to earn +60 Chips."`, `cost = 7`
- [x] 4.5 Create `scripts/charms/charm_straight_edge.gd` — extends `CharmEffect`; `on_score`: iterate `breakdown.combos`; if any entry's `.name` is `"Small Straight"` or `"Large Straight"`, `breakdown.charm_mult += 3.0` and return
- [x] 4.6 Create `resources/charms/straight_edge.tres` — `display_name = "Straight Edge"`, `description = "Score a Straight to earn +3 Mult."`, `cost = 5`

## 5. ShopScene pool update

- [x] 5.1 Extend `_CHARM_PATHS` in `scripts/shop_scene.gd` to include all 9 new `.tres` paths (keep existing 3; append the 9 new ones in the order: hair_trigger, adrenaline, patient_zero, ice_cold, big_bucks, precision, collector, high_roller, straight_edge)

## 6. Tests

- [x] 6.1 Create `tests/test_charm_catalog.gd` — headless GUT tests for all 9 new charms:
  - Hair Trigger: 2 W1 locks → charm_chips = 10; 0 W1 locks → 0
  - Adrenaline: 3 W1 locks → charm_mult = 1.0; 2 W1 locks → 0
  - Patient Zero: 4 W3 locks → charm_chips = 20; 0 W3 locks → 0
  - Ice Cold: all W2/W3 → charm_mult = 3.0; any W1 → 0
  - Big Bucks: one 5 + one 6 → charm_chips = 6; all low faces → 0
  - Precision: [4,4,4,4] → charm_mult = 2.0; [4,4,5,5] → 0
  - Collector: [1,2,3,4,5,6] → charm_mult = 6.0; [4,4,4,4] → 1.0
  - High Roller: Quad → charm_chips = 60; Triple → 0
  - Straight Edge: Large Straight → charm_mult = 3.0; Pair → 0

## 7. Verify on device

- [x] 7.1 Build APK and install on Pixel 9 — open shop across multiple antes, confirm all 12 charm names appear over time as pool rotates
- [x] 7.2 Buy Hair Trigger, lock 3 dice in W1 — confirm chips are visibly higher than baseline; buy Adrenaline alongside Quick Draw — confirm stacking works
- [x] 7.3 Buy Patient Zero, deliberately let dice reach W3 — confirm +5 Chips per W3 die; buy Ice Cold, skip W1 — confirm +3 Mult applied
- [x] 7.4 Buy High Roller, achieve a Quad — confirm +60 Chips; buy Straight Edge, hit a Large Straight — confirm +3 Mult
- [x] 7.5 Fill 5 inventory slots with a mix of archetypes — confirm BUY buttons disable correctly and score reflects all active charms
