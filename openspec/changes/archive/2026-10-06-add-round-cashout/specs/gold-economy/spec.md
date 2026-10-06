## ADDED Requirements

### Requirement: Income is itemised before the shop
Every shop visit's income (round reward, spare throws or skip reward, interest) SHALL be reported as line items in `RunCoordinator.last_cashout` / `cashout_ready`, computed from the same ledger operations that change the gold. Interest applies once per shop visit for both cleared and skipped rounds. The formulas are unchanged.

#### Scenario: Lines add up
- **WHEN** any round is cleared or skipped
- **THEN** `before + Σ lines == after == GoldLedger.gold`
