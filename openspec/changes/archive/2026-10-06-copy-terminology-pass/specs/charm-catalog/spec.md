## ADDED Requirements

### Requirement: Item text states the rule exactly
Every charm, die material and trinket description SHALL state its rule in plain words that match the rule maths. It SHALL use "×" for multiplication and "pips" for a die face's points. Current corrected text:
- Quick Draw: "Lock every die in Window 1: +2 Mult."
- Ice Cold: "Lock nothing in Window 1: +3 Mult."
- Snake Charmer: "A Pair of 1s scores 4 Mult, but no Pair chips."
- Collector: "+1 Mult for each different face you lock."
- Freeze Timer: "+2 s on the current lock window."
- Glass: "Scores ×2 pips, but shatters if re-rolled. Lock it before the first re-roll."
- Iron: "Tumbles slower (easier to read). Each face scores −1 pip."

#### Scenario: Quick Draw reads what it does
- **WHEN** Quick Draw fires
- **THEN** it adds +2 Mult, as its text says
