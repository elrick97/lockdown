## Why

UI/UX audit finding C2 (P0): during a lock window, CHIPS and MULT read 0, and the combo appears only after the throw resolves. The Heat dilemma at the heart of the game (PRD §3.2: bank a pair now for Heat, or gamble for a triple?) needs the player to see what the locked set is worth already. Today they have to do Yahtzee maths in 2.5 s (1.25 s on the boss). Balatro shows the hand type and its base Chips × Mult as soon as cards are selected, and keeps only the final total for the scoring animation. PRD trace: §2 *Readable depth*, *Flow under pressure*; §3.2 Heat dilemma.

## What Changes

- **Live preview of the hand:** on every lock, the best combo partition of the locked dice is computed by the existing pure scoring engine. Presentation only: no state changes, and charms are not run.
  - The status band shows it, for example "PAIR · 10 × 1" or "TWO PAIR · 25 × 2". With no combo yet it shows "No combo · keep locking".
  - The CHIPS and MULT plaques tick to the combo's base chips and mult with a small punch. This is Balatro's hand base. HEAT already updates live.
- **Cascade starts from the preview:** the cascade order becomes:
  1. stamp the combo (already in the plaques, so no re-add);
  2. dice add their pips;
  3. Gem chips;
  4. charm pulses;
  5. Heat;
  6. score.

  This matches Balatro's order: hand base, then cards, then jokers. The "what's shown sums to what's scored" invariant and its tests still hold.
- **Charms stay hidden in the preview:** their effects stay a surprise for the cascade, which keeps the *Jackpot payoff*. The final multiplied total is never previewed.

## Capabilities

### Modified Capabilities
- `score-cascade`: the step order starts from the combo base.
- `throw-loop`: adds the live locked-set preview.

## Impact

- `throw_scene.gd` (preview on `die_locked`), `score_cascade.gd` (step order), `score_hud.gd`.
- No scoring, Heat or timing change; it reuses `ScoringEngine.score` read-only.
- Tests: the preview equals the engine's combo base for the locked set; the steps still sum to the breakdown.

## Open question for review

- Should the preview include Gem chips and material pip changes? The recommendation is no: only the combo base, the same as Balatro, with dice pips added in the cascade.
