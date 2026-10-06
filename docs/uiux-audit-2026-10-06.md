# Lockdown — UI/UX Audit (2026-10-06)

Two passes merged: a research-backed audit by a review agent (sections 1–8), and a hands-on pass over states the playthrough never captures (section 9: focus cover, invalid actions, re-roll, boss idle, full/broke shop; captures in `build/audit/`). Section 10 lists corrections after code verification, and section 11 proposes the OpenSpec change sequence.

Scope: every state captured in `build/playthrough/*.png` (1080×2400), plus code in `scenes/throw/throw_scene.gd`, `scripts/score_hud.gd`, `scripts/score_cascade.gd`, `scripts/shop_scene.gd`, `scripts/start_scene.gd`, `scripts/ui_style.gd`, `resources/*`. Read-only; nothing in the project was modified. Phone-scale reasoning: 1080 px wide → ~393 pt on a 6" phone, so **1 pt ≈ 2.75 px** at base resolution.

---

## Executive summary

- **Big win: the score cascade.** CHIPS × MULT × HEAT plaques, per-die "+n" floats, a tiered stamp/shake/sparks, a charm-slot pulse, a target bar and tap-to-skip with a grace period. That's the right Balatro skeleton, and it's built as data (`FeedbackConfig`). Keep it.
- **Big win: the chrome.** The Blender 9-patch kit, oxblood felt and brass make it look like a game, not a prototype. Touch targets mostly meet 48 dp and sit in the thumb zone.
- **Biggest gap: you can't tell what you're building while you lock.** CHIPS/MULT read 0 for the whole lock window. There's no live combo preview, and a locked die only gets a faint amber floor ring. The core Heat dilemma (bank a pair now, or gamble?) needs the player to see "what I have so far" at a glance. Today they have to read pips under time pressure. (P0)
- **Discoverability is near zero after the start screen.** There's no combo list or values anywhere, no explanation of Heat beyond "speed heats up your score", and a boss rule ("windows halved") that the game never states. The only mid-run charm info goes into a status label that overflows the screen. (P0/P1)
- **Several feedback holes.** A round win cuts straight to the shop with no cash-out, so gold sources and interest are invisible. Can't-afford and slots-full give no reason. Taps on a locked die do nothing, or worse, can lock a neighbour. Pip modifiers (Iron −1, Glass ×2) show up as unexplained "+1" floats.
- **No pause/settings at all.** There's no manual pause, no screen-shake/reduced-motion toggle, no way to revisit how-to-play, and no abandon-run confirm. The timer urgency pulse runs at ~4.8 Hz, which conflicts with your own "never flicker" rule. (P1)
- **Some copy and terms are inconsistent.** "Pips" vs "Chips", "x2" vs "×3", "Throw 0 / 3" before the first throw, "throw(s)", and "×3 Mult" charms that animate as "+N". Small effort, large clarity gain.

---

## Principles reference

1. **Juice is a response to *every* input, cascading from small actions.** Jonasson & Purho, "Juice it or lose it" (2012). Summary: https://rpgplayground.com/research-making-a-juicy-game/ · list of talks: https://kenney.nl/knowledge-base/learning/must-see-videos-for-indie-developers
2. **Screenshake/kick sells impact, but scale it to the event.** Spamming it on every action dulls it. Nijman (Vlambeer), "The art of screenshake" (same sources as above).
3. **Game feel = real-time control + simulated space + polish.** Steve Swink, *Game Feel* (2008). The lock tap is your only real-time verb, so it deserves the most feel budget.
4. **Thumb zone: bottom-center is easy, top corners are hard.** 49% of users hold the phone one-handed. Hoober via Smashing: https://smashingmagazine.com/2016/09/the-thumb-zone-designing-for-mobile-users
5. **Touch targets ≥ 44 pt (Apple) / 48 dp (Material), and well spaced.** https://specification.website/spec/accessibility/touch-target-size/ · GAG "Ensure interactive elements… are large and well spaced" https://gameaccessibilityguidelines.com/full-list/
6. **No essential info by colour alone** (GAG, Basic). https://gameaccessibilityguidelines.com/full-list/
7. **Avoid flickering images; nothing faster than 3 flashes/s** (GAG Basic; WCAG 2.3.1). https://gameaccessibilityguidelines.com/full-list/ · https://wcag.dock.codes/documentation/wcag232
8. **Let players adjust game speed, and don't make precise timing essential: offer alternatives** (GAG Basic/Advanced). https://gameaccessibilityguidelines.com/full-list/
9. **Screen shake must be reducible or disableable.** Some low-vision players lose track of the scene after a shake. https://gameaccessibilityguidelines.com/?p=3102 · Xbox XAG 117: https://devdocs.xbox.com/gaming/accessibility/xbox-accessibility-guidelines/117
10. **Readable default font size; remind players of objectives/controls during play; interactive tutorials** (GAG). https://gameaccessibilityguidelines.com/full-list/
11. **Keyword tooltips everywhere a term appears** (Slay the Spire convention; distinct intent glyphs). https://sts2.untapped.gg/guides/how-to-read-enemy-intent
12. **Reference on demand: a hand list with values one tap away** (Balatro "Run Info"). https://cardgamer.com/games/getting-started-with-balatro/ · https://www.playbalatro.com/faq
13. **Options a juicy game must ship with: game speed, screenshake, effects intensity, high-contrast** (Balatro settings). https://www.whatsitlike.com.au/balatro-switch-review/ · https://blakecrosley.com/es/guides/design/balatro
14. **Spatial hierarchy: stable corners for status, centre for the action** (Dicey Dungeons layout analysis). https://mechanicsofmagic.com/?p=611

---

## Balatro & peers: what to borrow

| Game | What it does | Borrow for Lockdown |
|---|---|---|
| **Balatro: hand preview** | Selecting cards shows the hand name plus its base Chips × Mult *before* you play. Only the final total stays hidden for suspense. | During a lock window, show the **current best combo of the locked set** ("PAIR · 10 × 1") in the status band and seed the CHIPS/MULT plaques with it. Keep the final total hidden so the cascade keeps its drama. |
| **Balatro: Run Info** | Every poker hand, its level and its Chips/Mult, one button away mid-run. Secret hands stay hidden until discovered. | A **Combos** sheet (8 combos, example dice, base chips/mult), reachable from pause and from a "?" beside the HUD. Quint can stay "???" until first seen (serves Collect & unlock). |
| **Balatro: blind select** | Before each blind: target, reward, and the boss's rule in plain words. Skip offers its reward up front. | An **ante intro card** before throw 1: "BOSS — Lock windows halved (1.25 s)", target, and reward. On Risk: "Play for 4g + 1g per spare throw, or skip for 3g". |
| **Balatro: cash-out** | Itemised payout: blind reward, $ per remaining hand, interest. Then the shop. | A **round-cleared panel**: base 4g, +1g × spare throws, +interest, total. It's the only place the economy becomes legible. |
| **Balatro: tooltips + colour coding** | Chips are always blue and Mult always red, including in card text. "+Mult" and "×Mult" are visually different. | Give **CHIPS and MULT a consistent typographic/colour code inside descriptions** too (cream vs amber, plus a glyph). Render **×Mult differently from +Mult** in floats and copy. |
| **Balatro: options** | Game speed (×0.5–×4), screenshake, CRT/bloom intensity, high-contrast cards. | Cascade speed, shake strength 0/50/100%, reduced motion. Steady Mode/timer scale is already in PRD §4.6, so surface it in the same menu when M2 lands. |
| **Slay the Spire** | Every keyword in card text has a hover tooltip, and intent glyphs are unique and readable at a glance. | Long-press (or tap) any charm, die, or keyword ("Heat", "Pips", "Window") for a tooltip card. On mobile, use a **press-and-hold inspect** (Marvel Snap pattern). |
| **Luck be a Landlord** | Each symbol shows its payout floating on top of itself, and an inventory view lists every symbol you own. | Per-die floats already exist. Add a **bag view** (tap "YOUR DICE" / the bag counter) showing each die's material and carved face as icons. |
| **Dicey Dungeons** | Dice and slots are big, high-contrast and bordered, and a placed die visibly *sits in* the slot. | The **lock state needs that "seated" feeling**: lift and tint the die, a brass socket, and a padlock glyph. A thin floor ring isn't enough. |
| **Hades / Vampire Survivors** | VFX stay below gameplay readability. Damage numbers are capped and pooled so they never stack illegibly. | **Merge or queue the float texts** (see 18_charm_pulse.png, where three "+30 +30 +12" overlap). |
| **Marvel Snap** | The first match is scripted and teaches one rule per turn, with no text wall. Inspect any card by holding it. | A **first-run guided throw** (M3 "Tutorial" item). The cheap version is contextual one-line coach marks on first occurrence (see P1-T1). |

---

## Findings, screen by screen

Severity: **P0** blocks comprehension/core loop · **P1** important · **P2** nice. Effort: **S** < 2 h · **M** half–1 day · **L** multi-day.

### A. First launch / start screen (`21_start_screen.png`, `scripts/start_scene.gd`)

**A1 · P1 · How-to is the only teaching, and it's a text wall you can't revisit.**
- **What's wrong:** Four lines, shown once, gone forever after PLAY. "Make combos" doesn't say *which* combos exist. Nothing says locks are permanent.
- **Principle:** interactive tutorials; reminder of objectives during play (GAG).
- **Do:** keep the card, but (a) add a fifth idea, "Locks are final", and (b) put a "How to play" entry in the pause menu (C-pause below). (c) Add first-occurrence coach marks in the throw screen: first window "Tap a die to lock it", first resolve "Pair = 10 chips × 1 mult", first non-zero Heat "Heat: lock sooner = bigger multiplier", first shop "Charms change scoring rules".
- **Effort:** M.

**A2 · P2 · Single action, no secondary entries.**
- **What's wrong:** No settings, seed entry, or (later) collection. Fine for M1, but there's nowhere to put a shake toggle.
- **Do:** add a small secondary "Settings" button below PLAY, within thumb reach, and keep PLAY dominant.
- **Effort:** S.

**A3 · P2 · Transitions are hard cuts.** `get_tree().change_scene_to_file` everywhere (`run_coordinator.gd:56,61,73`, `start_scene.gd`, `throw_scene.gd`). Do: a 0.2–0.3 s fade/smoke wipe through a shared autoload, which also hides the 3D tray warm-up hitch. Effort: S.

### B. Throw screen: before the throw (`13_risk_skip_button.png`)

**B1 · P1 · The idle screen doesn't tell you what you're about to throw or need.**
- **What's wrong:** The tray is empty. "Throw 0 / 3" reads as "zero throws taken", while the meaningful number is "throw 1 of 3 is next". "Total: 0 / 350" doesn't say "target".
- **Evidence:** `throw_scene.gd:386`, 13.
- **Principle:** objective reminder (GAG).
- **Do:** label it "Throw 1 of 3" (next throw) and "350 TO BEAT" (or "Target 350") with the running total. Optionally add a "need ~117 per throw" hint after throw 1.
- **Effort:** S.

**B2 · P1 · Risk skip is a decision with only one side shown.**
- **What's wrong:** "SKIP RISK (+3g)" (`throw_scene.gd:108`). The player can't compare it with playing (4g base + 1g per spare throw + interest) or with the target's difficulty.
- **Principle:** Balatro blind-select shows both rewards.
- **Do:** move this into the ante intro card (see D3): "RISK ROUND · target 350 · win: 4g + 1g/spare throw · or SKIP for 3g".
- **Effort:** M (shared with D3).

### C. Throw screen: lock windows (`10`, `06`, `02`, `12`)

**C1 · P0 · Locked vs unlocked is too subtle under time pressure.**
- **What's wrong:** A locked die only gets a thin amber floor ring (`viewport_3d_dice_tumbler.gd:128`, `lock_ring.png`). The die itself is unchanged: same tint, same height. In `06_carving_spark_extends.png` the locked Spark die is distinguishable only by a 2-px outline. In `02` the locked Glass die looks almost identical to the "dead" shattered ones (DEAD_TINT 0.45 grey on amber glass reads as "darker glass", not "gone").
- **Principle:** signifiers, juice-per-input, no info by colour alone.
- **Do:**
  - Locked: raise the die ~8 px, put a lit brass socket under it, add a small padlock glyph, and darken unlocked dice ~10% while any are locked (figure/ground).
  - Dead: desaturate fully and add a crack overlay or "✕", plus a one-time "SHATTERED" float.
  - All of these are shape cues, so they're colourblind-safe.
- **Effort:** M (Blender socket and padlock art, tumbler code).

**C2 · P0 · No live readout of what the locked set is worth.**
- **What's wrong:** CHIPS 0 × MULT 0 for the whole window (10, 06, 12). The Heat dilemma the PRD calls central (§3.2) depends on knowing "I have a pair, it's worth X now". The player has to do Yahtzee maths in 2.5 s (1.25 s on boss).
- **Principle:** Balatro hand preview; readable depth pillar.
- **Do:**
  - On each lock, compute the best partition of the *currently locked* dice (the engine already does this) and show "PAIR" in the status band. Tick CHIPS/MULT to the provisional values with a small punch. HEAT already updates live.
  - Keep the final multiplied total hidden until the cascade.
  - The cascade then *continues* from these values (dice floats, charms, Heat) instead of restarting from 0.
- **Effort:** M. It's presentation only, and the scoring engine is reused.

**C3 · P1 · Tapping a locked die near its edge can lock the neighbour.**
- **What's wrong:** `_try_lock_at` skips locked and shattered dice and snaps to the nearest *unlocked* rect within 96 px (`throw_scene.gd:300-315`, `throw_config.tres tap_forgiveness_radius_px = 96`). Rect gaps are ~90 px at base resolution (measured from 10). A re-tap near the inner edge of an already-locked die can therefore lock the adjacent die. That's an irreversible mis-lock, with zero feedback on the intended tap.
- **Principle:** forgiveness must never produce a wrong irreversible action.
- **Do:** if the tap point is *inside* any die rect (locked or dead included), resolve to that die only. Apply forgiveness only to taps in gaps. Give a locked die a "denied" response: a small horizontal wiggle, padlock flash, and short buzz.
- **Effort:** S.

**C4 · P1 · Boss rule is never stated.**
- **What's wrong:** Only "ANTE 3 / 3 — BOSS ROUND" (12). Windows silently become 1.25 s, and a new player experiences it as "the game got glitchy/fast".
- **Principle:** telegraph modifiers (Balatro boss blind; StS intents).
- **Do:** an ante intro card (D3) plus a persistent small boss chip in the HUD ("⏱ ½ WINDOWS") that can be tapped for details. Optionally pulse the timer frame once on the first window.
- **Effort:** S–M.

**C5 · P1 · Timer urgency pulse is ~4.8 Hz.**
- **What's wrong:** `sin(Time.get_ticks_msec() * 0.03)` (`throw_scene.gd:276`) gives 30 rad/s, so ~4.8 cycles/s of brightness change on the timer fill and track during the last 0.8 s. That's above the 3/s flash guideline (small area, so probably not a seizure risk, but it reads as flicker, which the owner explicitly rejects). Oxblood-on-amber is also a weak contrast for red-green colour deficiency.
- **Do:** drop to ~2 Hz (`* 0.0125`) and make urgency mostly *shape*: the bar thickens and shakes slightly, and the remaining seconds appear as a number at the bar end ("0.6"). Keep the colour shift as a secondary cue.
- **Effort:** S.

**C6 · P1 · Every lock shakes the whole screen, HUD included.**
- **What's wrong:** `_screen_shake(_fx.lock_shake_px…)` (`throw_scene.gd:401`) moves `self`, so up to 6 locks per throw shake every label, and combo shakes reach 34 px. Nijman's point is that shake is strongest when reserved. Shaking the HUD text also hurts readability right when the player reads it.
- **Do:** apply lock feedback to the die and tray only (punch is already there). Keep full-screen shake for combo tiers ≥ 2 and target hit. Route all shake through one `shake_strength` setting (0/0.5/1).
- **Effort:** S.

**C7 · P2 · Trinket buttons sit where the eyes aren't.**
- **What's wrong:** Trinket buttons at y 1800–1930 (10) are fine for the thumb, but they're text-labelled ("Re-Tumble", "Freeze Timer"), which needs reading mid-window. Freeze Timer's copy says "Pause… 2 seconds" while the code *extends* the window by 2 s.
- **Do:** make the icon dominant, keep the label short, add a brief radial "used" burst, and fix the copy to "+2 s to this window".
- **Effort:** S.

**C8 · P2 · An empty timer track stays visible outside windows** (15, 16, 17, 13). An empty brass tube reads as "broken bar". Do: fade the track to 30% when not in a window, or reuse the band for the round-target bar. Effort: S.

### D. Resolution / cascade / round end (`15`, `16`, `17`, `18`, `04`, `01`)

**D1 · P1 · Float texts stack into illegible piles.**
- **What's wrong:** In 18, "+30 / +30 / +12" overlap on top of the CHIPS caption, and "+5" sits on top of the MULT value "8".
- **Principle:** the Hades/VS readable-damage-number rule.
- **Do:** queue the floats at each anchor with a vertical offset per active float, or merge same-frame deltas ("+72"). Never overlap the plaque value: spawn above the plaque and drift up.
- **Effort:** S.

**D2 · P1 · The stamp parks over the dice and stays after the cascade.**
- **What's wrong:** In 17 the score has landed, but "PAIR + TWO PAIR" still covers the middle row of dice. The board you'd want to review is hidden. Nothing shows *which* dice formed *which* combo.
- **Do:** stamp, hold ~0.6 s, then shrink-fly it into the status band ("PAIR + TWO PAIR · 238"). During the combo step, flash the member dice of each combo in sequence (pair dice, then two-pair dice) so the grouping is visible.
- **Effort:** M.

**D3 · P1 · No round-cleared / cash-out moment; the economy is invisible.**
- **What's wrong:** On a win, `_on_ante_advanced` → `RunCoordinator.on_ante_cleared` changes scene immediately after "TARGET HIT!" (`run_coordinator.gd:49-56`). Gold sources (base 4g, +1g per spare throw, 25% interest capped) are never shown. The shop just says "Gold: N".
- **Principle:** feedback for every reward (Juice it); Balatro cash-out.
- **Do:** add a "ROUND CLEARED" panel in the throw scene. Itemised gold lines tick in, then the total is stamped. CONTINUE goes to the shop and doubles as the pacing breather. Reuse the end-panel card.
- **Effort:** M.

**D4 · P1 · Pip modifiers are shown but never explained.**
- **What's wrong:** In 01, an Iron die showing 2 floats "+1". In 03, Glass doubles silently. The player thinks the game miscounted.
- **Do:** append the reason to the float ("+1 IRON −1", "+12 GLASS ×2"), or float the base value then a second modifier float. Also mark material on the die in the bag view (G-list).
- **Effort:** S.

**D5 · P1 · Status copy after a throw is redundant and programmer-ish.**
- **What's wrong:** "Score 238 — 2 throw(s) left" (`throw_scene.gd:470`) duplicates "238 pts" right below it and "Throw 1 / 3" above it.
- **Do:** replace with the actionable delta: "112 TO GO · 2 THROWS LEFT", or "LAST THROW · NEED 112" in amber on the final throw.
- **Effort:** S.

**D6 · P2 · "TAP TO SKIP" is low-contrast and tiny.** 30 px MUTED (#8A7A64) on dark gives ~11 pt at phone size (15, 16). It's discoverable once, which is fine, but bump it to 36 px and show it only on the first few cascades, then hide it (the gesture remains). Effort: S.

**D7 · P2 · Shown maths is momentarily inconsistent.** In 16, "53 × 3 × 1.50" sits above "9 pts" because the tick-up starts from 0. Balatro avoids this by showing the product flying into the score. Do: animate the three plaques collapsing into the result label before it ticks, or tick fast from the product. Effort: S.

### E. Charms during play (`18`, `throw_scene.gd:553-576`)

**E1 · P0 · The only mid-run charm info overflows the screen and is then overwritten.**
- **What's wrong:** Tapping a slot sets `_status.text = "%s: %s"` (`throw_scene.gd:572`). `Status` is a 48 px label with no autowrap, on a 1000 px band (`throw_scene.tscn:39-45`, re-laid at `270–360`). Example: "Snake Charmer: Snake eyes (pair of 1s) score at ×4 Mult instead." is ~1,400 px, which clips off both screen edges. The next state change ("Window 1 / 3…") also wipes it. Empty slots show nothing. This is the Readable depth pillar's main channel.
- **Principle:** keyword tooltips on demand (StS, Balatro).
- **Do:** press-and-hold, or tap, a charm to open an **inspect card** anchored above the charm row. It shows the medallion, name, rule text (with Chips/Mult coded), and archetype tag, and dismisses on release or tap elsewhere. Use the same component in the shop and on the end panel. During a lock window, holding should be allowed but must not pause the timer, unless Steady Mode.
- **Effort:** M.

**E2 · P1 · "×N Mult" charms animate as "+N".**
- **What's wrong:** `_float_delta` always prints `"+" + fmt_mult(m)` (`score_cascade.gd`, `_float_delta`), and charm triggers are recorded as additive mult deltas (`scoring_engine.gd:65-70`). So Quick Draw ("×3 Mult") shows "+6" when mult was 3. The copy and the animation disagree, which undermines trust in the maths.
- **Do:** carry an `op` (`add` / `mul`) in `charm_triggers`. Show "×3" in a distinct style: larger, amber with a brass outline, and a different pop. Balatro's ×Mult has its own visual identity for exactly this reason.
- **Effort:** S–M.

### F. Shop (`19_charm_shop.png`, `14_risk_skip_shop.png`, `scripts/shop_scene.gd`)

**F1 · P1 · Can't-afford and slots-full are silent.**
- **What's wrong:** BUY is disabled (`shop_scene.gd:305-314`), but every disabled BUY looks the same as an affordable-but-muted one (14: gold 3, all three BUY look identical; 19: gold 0). The price isn't flagged. With 5/5 charms, a charm card just has a dead button with no reason, and `_on_buy_pressed` returns silently (`:238-242`).
- **Principle:** feedback for invalid actions (Juice; Norman's signifiers).
- **Do:**
  - Show unaffordable prices in a muted-red/strikethrough style plus a "NEED 3g MORE" caption on the button.
  - With full slots, label the button "SLOTS FULL", or (M2) offer "SELL…" to swap.
  - Tapping a disabled BUY should still wiggle it and pulse the gold plaque.
- **Effort:** S.

**F2 · P1 · Purchases have no payoff animation.**
- **What's wrong:** "Bought: X" goes into a status label (`:253`) and the card greys out (`:314`). Buying a charm is the run's big "collect" moment (pillar 5).
- **Do:** the medallion flies from the card into the next empty socket and lands with a punch and sparks. The gold plaque ticks down. A die purchase flies into "YOUR DICE".
- **Effort:** M.

**F3 · P1 · No look-ahead in the shop.**
- **What's wrong:** You buy blind to the next target (350/700) and to the boss rule (halved windows, where speed charms matter more).
- **Principle:** informed decisions = readable depth.
- **Do:** a "NEXT: ANTE 3 · BOSS · target 700 · ½ windows" strip above "Choose an upgrade", filling the dead space between "YOUR DICE" and the offers (19 has ~250 px of empty felt there).
- **Effort:** S.

**F4 · P1 · "YOUR DICE: 8 Bone" is a text summary, not a bag.**
- **What's wrong:** After buying Glass, Iron or carved dice, the player can't see faces or materials. Carved names like "Wild 6 (Bone)" read as debug strings.
- **Do:** a row of mini die icons (material colour plus carved glyph) that can be tapped for the inspect card. Rename to "Bone die · Wild on 6".
- **Effort:** M.

**F5 · P2 · Copy issues in descriptions.**
- "Ice Cold: Skip Window 1 entirely" is ambiguous. Better: "Lock nothing in Window 1: +3 Mult".
- "Snake eyes" is jargon. Better: "Pair of 1s".
- "x2 Pips" vs "×3 Mult": unify on "×".
- "Pips" (materials) vs "Chips" (HUD): pick one public term (see H1).

Effort: S.

**F6 · P2 · Charm row in the shop isn't inspectable** (the medallions are static `UiStyle.charm_row`). Reuse the E1 inspect card. Effort: S once E1 exists.

### G. End of run (`22_end_panel_game_over.png`)

**G1 · P1 · Losing tells you the score but not why or how close.**
- **What's wrong:** "57" and "FINAL TOTAL / TARGET 150" are there, but there's no "93 short", no per-throw breakdown, no best combo, and no peak Heat. "GAME OVER." also shows twice (the status label behind the panel reads "GAME OVER." with a period, `throw_scene.gd:494-497`).
- **Principle:** roguelike run summaries drive "one more run" (the M0 gate metric).
- **Do:** add "MISSED BY 93" in muted red under the total. Add a stat row: best combo, best throw, fastest lock / avg Heat, gold earned, rounds cleared. Clear `_status` when the panel shows.
- **Effort:** S–M.

**G2 · P2 · The seed is displayed but not usable.** "Seed 109726632" can't be copied or replayed. Do: tap the seed to copy it (`DisplayServer.clipboard_set`), and (later) add "Replay seed" in settings. Effort: S.

**G3 · P2 · An empty build row on a loss looks like a bug.** Five empty sockets in 22. Do: if 0 charms, show "No charms this run" instead of five empty sockets. Effort: S.

### H. Cross-cutting

**H1 · P1 · Terminology drift.**
- "Pips" (materials, PRD formula) vs "CHIPS" (HUD); "Window" (status) vs "lock window" (copy); "Total" vs "target"; "Throw 0/3" semantics; "Heat ×1.50" as a pre-throw idle value with no explanation.
- **Do:** pick public terms: **Pips** (face value) → become **Chips**; Mult; Heat; Window. Then (a) write a 6-entry glossary used by tooltips, and (b) make the cascade say it: the die float reads "+6 pips" the first time.
- **Effort:** S.

**H2 · P1 · Small text at phone scale.**
- HUD captions "CHIPS/MULT/HEAT" are 22 px ≈ 8 pt (`score_hud.gd:78`). The HEAT value is 44 px vs 60 for the others. SlotButton is 28 px. Muted #8A7A64 captions on the dark plaque are borderline (~4:1).
- **Principle:** "Use an easily readable default font size" (GAG).
- **Do:** set a minimum of 30 px (~11 pt) for any caption, raise the HEAT value to 52 px, and brighten MUTED to ~#A8977C.
- **Effort:** S.

**H3 · P1 · No pause / settings / abandon.**
- **What's wrong:** Pause only exists as the focus-loss cover. A player can't pause to read, change settings, re-read how-to, or quit a run, which is a basic expectation on mobile.
- **Principle:** GAG pausing/reminders; Balatro options.
- **Do:** a small ⏸ in the HUD panel's top-right corner. Top corners are the hard reach zone, which is appropriate for a rare, non-urgent action, and it can't be hit by accident during locks. It reuses the focus cover: obscure the tray, then do the 3-2-1 resume with the window restarted (existing spec rule).
- **Menu:** Resume · How to play · Combos · Settings (shake 0/50/100, cascade speed 1×/2×/instant, reduced motion, haptics toggle; later timer scale and Steady Mode per PRD §4.6) · Abandon run (confirm dialog).
- **Note:** a persisted settings file is plumbing, so this can be batched per CLAUDE.md.
- **Effort:** M–L.

**H4 · P1 · Colour carries Chips vs Mult on its own.**
- **What's wrong:** CHIPS is cream and MULT is amber; both are warm and only differ in value. The palette rule allows only one saturated hue, so don't add blue/red. Instead, rely on shape.
- **Do:** give each plaque a distinct glyph (a chip disc vs a "×" badge), keep CHIPS numerals in plain cream and MULT numerals in amber with a heavier outline, and repeat the same glyphs in description text. Optionally, if the owner is open to it, add a desaturated slate-blue CHIPS plaque as an art-direction amendment.
- **Effort:** S–M.

**H5 · P2 · Haptics on every lock with no toggle** (`throw_scene.gd:402`). Add it to settings (PRD §4.6 already lists a haptics toggle). Effort: S.

---

## Gaps / forgotten features

1. **Live combo preview while locking** (C2): the single biggest readability lever.
2. **Combos reference sheet** ("Run Info"): combos, example dice, base chips/mult, and which charms touch them.
3. **Pause menu + Settings** (shake, cascade speed, reduced motion, haptics; later timer scale/Steady Mode).
4. **Ante intro card** (target, reward, boss/risk rule, skip comparison).
5. **Round-cleared cash-out panel** (itemised gold, interest).
6. **Inspect card / tooltips** for charms, dice, trinkets and keywords, shared across throw, shop and end panel.
7. **Bag view** (dice owned, materials, carved faces), reachable in shop and pause.
8. **Abandon-run confirm and "how to play" revisit.**
9. **Invalid-action feedback set:** locked-die tap, can't afford, slots full, trinket with nothing to re-tumble.
10. **Run summary stats** on the end panel, plus a copyable seed.
11. **First-occurrence coach marks** as a cheap bridge to the M3 tutorial.
12. **Scene transitions** (smoke wipe).
13. Later, out of M1 scope: collection journal surface on the start screen, run history, Steady Mode exposure.
14. **Audio** is deferred by owner decision, not a gap. Note that several of the recommendations above (denied-tap, cash-out tick) will want SFX hooks when audio lands. Keep the stubbed `AudioStreamPlayer` pattern.

---

## Things that are already good (keep)

- **Cascade architecture:** pure `build_steps`, step timings in `FeedbackConfig`, tier-scaled shake and sparks, and "what's shown sums to what's scored". It's exactly the right Balatro lesson and testable headless.
- **Tap-to-skip with a grace period** (`skip_grace_s` = 0.35), so the tap that locks the last die never eats its own payoff. A thoughtful detail.
- **Charm slot pulse** in slot order when a charm fires. That's Balatro's joker-trigger clarity.
- **Tap forgiveness radius**, at least in the gaps (fix the inside-a-locked-die case only).
- **Focus-loss cover** with a capped-delta countdown and window restart. It's generous and handles web tab blur.
- **Live Heat readout** during windows: the speed reward is visible as it drains.
- **Layout discipline:** all frequent controls in the bottom 40%, 48 dp minimum, verified by tests. THROW is big, centred and oxblood, and the shop's BUY sits on the right edge in thumb reach.
- **Chrome and lighting:** 9-patch brass, felt lamp pool, soft edge fog (non-flickering, measured). The Iron/Bone/Glass value separation reads well (01, 02).
- **Start screen restraint:** one action and a breathing PLAY. The hero art does the selling without a logo.
- **End panel stamp + count-up:** the right shape. It just needs content (G1).

---

## Prioritised top 10

| # | Action | Sev | Effort | Pillar served |
|---|---|---|---|---|
| 1 | **Live locked-set preview**: combo name plus provisional CHIPS/MULT during windows; cascade continues from it (C2) | P0 | M | Readable depth, Flow under pressure |
| 2 | **Strong lock and dead signifiers**: lift, socket, padlock, dim the unlocked dice; crack/✕ for shattered (C1) | P0 | M | Flow under pressure, One thumb |
| 3 | **Charm inspect card** (hold/tap), shared by throw/shop/end; remove the overflowing status-line tooltip (E1, F6) | P0 | M | Readable depth |
| 4 | **Fix the mis-lock**: taps inside a locked die never forgive to a neighbour, plus denied-tap feedback (C3) | P1 | S | Flow under pressure |
| 5 | **Ante intro card** (target, reward, boss rule, risk skip comparison) plus a HUD boss chip (B2, C4, F3) | P1 | M | Readable depth |
| 6 | **Round-cleared cash-out panel** with itemised gold (D3) | P1 | M | Jackpot payoff, Collect |
| 7 | **Pause menu + Settings** (shake %, cascade speed, reduced motion, haptics, how-to, combos sheet, abandon-confirm) (H3, A1, H5) | P1 | M–L | One thumb; accessibility (PRD §4.6) |
| 8 | **Feedback hygiene**: lock shake on the tray only, urgency pulse ≤ 2 Hz plus a numeric countdown, float queueing, stamp flies out of the way (C5, C6, D1, D2) | P1 | S–M | Jackpot payoff without noise |
| 9 | **Shop invalid-state clarity and purchase payoff**: "NEED 3g MORE", "SLOTS FULL", medallion fly-in (F1, F2) | P1 | S–M | Collect & unlock |
| 10 | **Copy/terminology pass**: Throw "1 of 3", "Target", "112 TO GO", ×Mult vs +Mult rendering, Pips→Chips, Ice Cold/Snake Charmer/Freeze Timer copy, 30 px caption minimum (B1, D5, E2, F5, H1, H2) | P1 | S | Readable depth |

**Process notes (per CLAUDE.md):**
- Items 1, 2, 4, 5, 6 and 8 touch throw-loop/score-cascade presentation, so each is its own OpenSpec change with human review between artifacts.
- Item 7 is plumbing-heavy (settings persistence), so batching its artifacts is acceptable.
- None of these changes Heat or ante curves, so no balance-sim run is needed.
- All are locally verifiable: GUT for the preview maths and tap resolution, plus a desktop 1080×2400 playthrough.
- No new dependencies are needed. New art (socket, padlock, crack, pause/gear icons) should come from Blender, per the chrome rule.

---

## 9. Hands-on additions (states the playthrough doesn't capture)

- **Focus-loss cover says nothing** (`build/audit/03_focus_cover.png`, `04_countdown.png`). It's a blank dark screen, then a lone "3", with no "PAUSED" label or "resume in…" context. Add a title and a one-line hint. This folds into H3 (pause menu). P1 · S.
- **Failed buy is fully silent.** With 0 gold and 5/5 charms, tapping BUY leaves the status on "Choose an upgrade" (verified by script output). The disabled BUY art is also hard to tell from the normal art at phone size. This confirms F1. P1 · S.
- **Empty felt before the first throw** (`05_boss_idle.png`). The biggest area on screen is empty. Show the drawn dice resting in place, or ghost dice, so the tray never looks broken. P2 · S.
- **The charm-name line duplicates the medallions and wraps** ("Big / Bucks", `06_shop_full_broke.png`). Once the inspect card exists (E1), shorten it to "Charms 5 / 5". P2 · S.
- **Invalid taps outside a window** (while tumbling) are silent. A tiny "wait" wiggle on the die would help. P2 · S.

## 10. Corrections after code verification

- **C3 (mis-lock): confirmed in code.** `_try_lock_at` (`throw_scene.gd:300-315`) skips locked and shattered dice and snaps to the nearest *unlocked* rect within `tap_forgiveness_radius_px = 96`. A tap on a locked die can therefore lock its neighbour.
- **E1 (charm text overflow): confirmed.** The `Status` label (`throw_scene.tscn:39-45`) has no autowrap.
- **E2 is mis-stated.** Quick Draw's rule *adds* +2 Mult (`charm_quick_draw.gd`, spec "charm_mult += 2.0"), and the cascade correctly shows "+2". The bug is the **copy**: the card says "×3 Mult". Fix the description (e.g. "+2 Mult") rather than the animation. The `op: add/mul` idea is still worth having when real ×Mult charms arrive in M2.
- **C5 (pulse rate):** 30 rad/s ≈ 4.8 Hz, confirmed in `_update_urgency`. It conflicts with the owner's "never flicker" rule, so fix it in the feedback-hygiene change.

## 11. Proposed change sequence (one OpenSpec change each, per CLAUDE.md)

1. `fix-tap-lock-resolution`: C3 plus denied-tap wiggle (S, bug fix, do first).
2. `add-live-lock-preview`: C2 (P0). Gameplay-critical presentation, so review between artifacts.
3. `add-lock-signifiers`: C1 (P0). Blender socket and padlock, dead-die crack.
4. `add-inspect-card`: E1/F6 (P0). Shared hold/tap inspect for charms, dice and trinkets.
5. `add-feedback-hygiene`: C5, C6, D1, D2 (S–M).
6. `add-ante-intro-card`: B2, C4, F3, and the boss HUD chip.
7. `add-round-cashout`: D3.
8. `add-pause-settings`: H3, A1, H5 and the focus-cover copy. Plumbing-heavy, so artifacts can be batched.
9. `add-shop-clarity`: F1, F2, F4.
10. `copy-terminology-pass`: B1, D5, E2-copy, F5, H1, H2.
11. `add-run-summary-stats`: G1–G3.
