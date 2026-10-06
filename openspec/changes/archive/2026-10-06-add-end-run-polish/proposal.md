## Why

The end-of-run panel was the plainest screen left: a text title over a text summary. It was also visually broken: the charm row and THROW drew above the dimmer, so they stayed bright behind the panel. The run's ending is the biggest payoff moment, and it read weaker than a single Pair. The owner's direction (2026-10-06) is to keep improving style and UI/UX. PRD trace: §2 *Jackpot payoff*, §5 juice, run-flow end-of-run panel.

**Pillars served:** *Jackpot payoff*: the end of the run lands like a big combo. *Readable depth*: the final total is the headline, the build is shown under a caption, and nothing behind the panel competes with it.

## What Changes

- **Stamped title:** RUN WON (amber) or GAME OVER (cream) slams in as a tilted stamp, in the same style as the combo banner, and overhangs the card's top edge. A win gets a tier-4 shake and a tier-5 spark burst; a loss gets a tier-2 thud with no sparks.
- **Final total as the headline:** it counts up from 0, using the same score-scaled tick as the cascade, and lands with a punch. A caption above it shows the target.
- **Compact summary:** "Ante x / y · Best throw n" plus the seed, then the build medallions under a "YOUR BUILD" caption.
- **Buttons:** NEW RUN is the primary (oxblood) button; MENU stays secondary.
- **Draw-order fix:** the panel dims everything below it (tray, HUD, charm row), the focus cover stays on top, and THROW is hidden while the panel shows.
- **Shared HUD helpers:** `ScoreHud.style_stamp`, `ScoreHud.slam` and `ScoreHud.spawn_burst` are now static helpers that the panel shares with the combo stamp.

## Capabilities

### Modified Capabilities
- `run-flow`: the end-of-run panel presentation.

## Impact

- `scenes/throw/throw_scene.gd` (end panel and draw order) and `scripts/score_hud.gd` (static helpers).
- No rule change.

## Non-goals

- Run history or stats screen (M2).
- Sharing a run (post-MVP).
