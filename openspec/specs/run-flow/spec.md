# run-flow Specification

## Purpose
The run lifecycle around the throw loop: start screen with how-to, end-of-run panel, new run / menu transitions and the run summary.
## Requirements
### Requirement: Start screen with how-to
The game SHALL open on a start screen showing:
- **Mark:** the rendered start hero (`res://assets/ui/start_hero.png`), with no game name or logo until PRD Q4 is resolved. It floats in a gentle idle bob (`HERO_BOB_PX` = 14 px, `HERO_BOB_S` = 3.2 s).
- **How-to:** at most four short lines covering throw, tap-to-lock before the timer runs out, only locked dice score, and faster locks raise Heat.
- **PLAY button:** in the bottom thumb zone, with a slow breathing scale pulse.

PLAY SHALL start a fresh run (`RunCoordinator.new_run()`) and open the throw screen at ante 1.

#### Scenario: First launch
- **WHEN** the game starts
- **THEN** the start screen shows the hero, the how-to and PLAY, and no run timer is running

#### Scenario: Play
- **WHEN** the player presses PLAY
- **THEN** a fresh run starts (ante 1, 0 gold, empty charm and trinket slots, starting bag, new seed) and the throw screen opens

### Requirement: End-of-run panel
When the run is won or lost, the throw screen SHALL show an end-of-run panel over a dimmer that covers everything on the throw screen; only the focus cover draws above it. THROW SHALL be hidden and disabled while the panel shows. The panel shows:
- **Result:** "RUN WON" (amber) or "GAME OVER" (cream), as a tilted stamp that slams in. A win shakes the screen at tier 4 and bursts sparks at tier 5; a loss shakes at tier 2 with no sparks. Tier values are from `FeedbackConfig`.
- **Final round total:** the headline. It counts up from 0 using the cascade's score-scaled tick and lands with a punch, with a caption giving the target.
- **Summary:** the ante reached out of the total, the best single-throw score, and the run seed.
- **Build:** the run's charm medallions under a "YOUR BUILD" caption.
- **Buttons:** NEW RUN (primary) and MENU, in the bottom thumb zone.

NEW RUN SHALL start a fresh run and reload the throw screen; MENU SHALL return to the start screen.

#### Scenario: Game over
- **WHEN** the final throw of a round leaves the total below target
- **THEN** the panel stamps GAME OVER, counts the final total up from 0 to the round total, lists the ante reached and best throw, and NEW RUN and MENU are enabled

#### Scenario: Run won
- **WHEN** the final ante's target is met
- **THEN** the panel stamps RUN WON with a shake and spark burst, and shows the same summary

#### Scenario: Nothing bright behind the panel
- **WHEN** the panel is shown
- **THEN** the tray, HUD, charm row and THROW are all drawn below the dimmer, and THROW is hidden

### Requirement: Run summary
`RunCoordinator` SHALL record the best single-throw final score of the current run (updated when each throw's cascade finishes) for the end-of-run panel. `new_run(seed = 0)` SHALL call `end_run()` then `start_run(seed)`, so the summary resets with the run. The summary is presentation data and SHALL NOT affect scoring.

#### Scenario: Best throw kept
- **WHEN** throws score 40, 120 and 90 in one run
- **THEN** the recorded best throw is 120, and it is 0 again after `new_run()`

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

### Requirement: Abandon run
The pause menu's Abandon run SHALL ask for confirmation ("The run ends now and counts as a loss"). Confirming unpauses, skips any running cascade, and ends the run as a loss through the end-of-run panel. The throw loop never ticks behind the end panel.

#### Scenario: Abandon
- **WHEN** the player confirms Abandon run
- **THEN** the end panel shows GAME OVER and the run is over

### Requirement: End-of-run stats and copyable seed
The end-of-run panel SHALL say how close the run came and what went well:
- **Result line:** under the final total, "MISSED BY <n>" (muted red) on a loss, or "BEAT BY <n>" (amber) on a win.
- **Summary:**
  - "Ante <a> / <total> · Best throw <n>";
  - "Best combo: <name>" (or "—");
  - "Rounds cleared <n> · Gold earned <g>".

  `RunCoordinator` records these per run as presentation data (`best_combo_type`, `rounds_cleared`, `gold_earned`), reset with the run; scoring never reads them.
- **Seed:** "Seed <n> · tap to copy". Tapping it copies the seed to the clipboard and floats "Copied".
- **Build:** with no charms, "No charms this run" replaces the empty sockets.
- **Behind the panel:** the status line is cleared and the ante intro card is closed.

#### Scenario: Close loss
- **WHEN** a run ends with 57 of 150
- **THEN** the panel reads "MISSED BY 93" under the total

#### Scenario: Seed copy
- **WHEN** the player taps the seed
- **THEN** the seed is on the clipboard and "Copied" floats up

### Requirement: Screen transitions
Every screen change SHALL go through the `SceneFader` autoload, and SHALL NOT be a hard cut. This covers start → throw, throw → shop, shop → throw, NEW RUN and MENU.
1. A full-screen smoke wipe covers the screen over `TRANSITION_S` (current 0.22 s).
2. The scene swaps under cover. The new screen draws for two frames.
3. The wipe reveals it over `TRANSITION_S`.

Taps are blocked while the wipe is up. With reduced motion, the wipe is a plain fade over `PLAIN_S` (0.15 s). Tools and tests can set `SceneFader.instant` for immediate swaps.

#### Scenario: PLAY
- **WHEN** the player presses PLAY
- **THEN** smoke covers the start screen, the throw screen is revealed, and taps work again once revealed

