## ADDED Requirements

### Requirement: Round-cleared cash-out panel
When `RunCoordinator` emits `cashout_ready`, the throw screen SHALL show a cash-out panel over a dimmer, with THROW hidden:
- **Title:** "ROUND CLEARED" (or "ROUND SKIPPED"), stamped in.
- **Itemised gold lines** that fade in one by one, with the signed amount right-aligned:
  - "Round reward" +base;
  - "Spare throws ×N" +N × per-throw, when N > 0;
  - "Skipped risk round" +3, when skipping;
  - "Interest (25% of X, max 40)" ±Y. This can be negative when the gold cap clips.
- **Gold total:** a "GOLD" total that counts up from the gold before the round to the gold after.
- **CONTINUE** (primary): goes to the shop.

The lines SHALL sum exactly to the change in gold, and the final total equals the gold the shop opens with.

#### Scenario: Two spare throws
- **GIVEN** 6 gold
- **WHEN** a round is cleared with 2 throws left
- **THEN** the panel lists +4g, +2g and +3g interest, and the total counts from 6 to 15

#### Scenario: Cap clips interest
- **WHEN** credited gold plus interest would exceed `max_gold`
- **THEN** the interest line shows the clipped amount and the total equals `max_gold`
