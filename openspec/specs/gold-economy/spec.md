# gold-economy Specification

## Purpose
The gold economy between antes: income, interest, purchases and re-roll costs.

Named tunables on `ShopConfig` Resource (current values): `base_gold_per_ante` = **4**, `gold_per_leftover_throw` = **1**, `interest_rate` = **0.25**, `max_gold` = **40**, `reroll_cost` = **1**, `offer_slots` = **3**.

## Requirements

### Requirement: Gold earned after each ante
After an ante is cleared, the system SHALL award gold equal to `base_gold_per_ante + (throws_left * gold_per_leftover_throw)`, where `throws_left` is the number of unused throws in the final round. Both tunables are exposed in `ShopConfig`.

#### Scenario: Full throws used
- **WHEN** a player clears ante 1 using all 3 throws (throws_left = 0)
- **THEN** gold earned equals `ShopConfig.base_gold_per_ante`

#### Scenario: Leftover throws bonus
- **WHEN** a player clears ante 1 with 2 throws to spare
- **THEN** gold earned equals `base_gold_per_ante + 2 * gold_per_leftover_throw`

### Requirement: Interest applied before spending
At the start of each shop visit, the system SHALL apply interest: `gold += floor(gold * interest_rate)`, then clamp to `max_gold`. Interest is applied once per visit, before any purchases.

#### Scenario: Interest on savings
- **WHEN** the player enters the shop with 6 gold and `interest_rate = 0.25`
- **THEN** gold becomes `6 + floor(6 * 0.25) = 7` before any offer is shown

#### Scenario: Gold capped at max_gold
- **WHEN** interest would push gold above `ShopConfig.max_gold`
- **THEN** gold is clamped to `max_gold`

### Requirement: Purchases deduct gold
Buying an offer SHALL deduct its `cost` from the player's gold. A purchase SHALL be rejected (BUY button disabled) if the player's gold is less than the offer cost.

#### Scenario: Successful purchase
- **WHEN** the player has 5 gold and buys an offer costing 3
- **THEN** gold becomes 2 and the offer slot is marked sold

#### Scenario: Cannot afford
- **WHEN** the player has 1 gold and an offer costs 3
- **THEN** the BUY button for that offer is disabled and gold is unchanged

### Requirement: Re-roll costs gold
Pressing RE-ROLL SHALL deduct `ShopConfig.reroll_cost` (default 1) from gold and refresh all unsold offer slots. RE-ROLL is disabled when gold < reroll_cost.

#### Scenario: Re-roll deducts gold
- **WHEN** the player has 3 gold and presses RE-ROLL (cost 1)
- **THEN** gold becomes 2 and the offer slots refresh

#### Scenario: Cannot re-roll without gold
- **WHEN** the player has 0 gold
- **THEN** the RE-ROLL button is disabled

### Requirement: Gold persists across antes within a run
`GoldLedger` SHALL be owned by `RunCoordinator` and survive scene transitions between `ThrowScene` and `ShopScene`. Gold SHALL NOT be reset between antes.

#### Scenario: Gold carries over
- **WHEN** the player enters the shop with 4 gold, buys nothing, and presses CONTINUE
- **THEN** gold is still 4 when the next ante's shop opens (after interest)
