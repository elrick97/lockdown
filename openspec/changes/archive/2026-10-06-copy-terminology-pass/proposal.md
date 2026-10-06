## Why

UI/UX audit findings E2-copy, F5, D5, H1, H2 and C7:
- **Copy that contradicts the rules:**
  - Quick Draw says "×3 Mult" but adds +2.
  - Freeze Timer says "Pause… 2 seconds" but adds 2 s to the window.
  - Ice Cold's "Skip Window 1 entirely" is ambiguous.
  - Snake Charmer's "Snake eyes" is jargon and hides that the Pair's chips are dropped.
- **Inconsistent wording:**
  - "x2" vs "×2".
  - "Pips" vs "Chips" used without explanation.
  - "Score 238 — 2 throw(s) left" repeats the score and reads like a debug string.
- **Captions too small:** the plaque captions are 22 px, about 8 pt on a phone, and the muted caption colour is borderline contrast.

PRD trace: §2 *Readable depth*. Content text lives in `.tres` (content is data), and no rule changes.

## What Changes

- **Charm and item text** (description only; rules untouched):
  - Quick Draw: "Lock every die in Window 1: +2 Mult."
  - Ice Cold: "Lock nothing in Window 1: +3 Mult."
  - Snake Charmer: "A Pair of 1s scores 4 Mult, but no Pair chips."
  - Collector: "+1 Mult for each different face you lock."
  - Freeze Timer: "+2 s on the current lock window."
  - Glass: "Scores ×2 pips, but shatters if re-rolled. Lock it before the first re-roll."
  - Iron: "Tumbles slower (easier to read). Each face scores −1 pip."
- **Terms:** "pips" means a die face's points, and CHIPS is pips plus bonuses. The Combos page reminder and the inspect card for dice say so. "×" is used everywhere.
- **Status copy after a throw:**
  - "238 scored · 112 to go · 2 throws left";
  - on the last throw, "LAST THROW · NEED 112";
  - after the target is met, "Target hit!"
- **Readability:** captions are at least 30 px (plaque captions, YOUR BUILD / YOUR DICE, TAP TO SKIP), HEAT is 52 px, and `MUTED` is brightened to #A8977C.

## Capabilities

### Modified Capabilities
- `charm-catalog`: description copy.
- `ui-theme`: minimum caption size, the muted colour, and status copy.

## Impact

- Charm, material and trinket `.tres` descriptions; `score_hud.gd`, `throw_scene.gd` and `shop_scene.gd` font sizes; `ui_style.gd` MUTED.
- Tests: descriptions match the rule maths for the corrected charms; caption sizes are at least 30.
