# LOCKDOWN — Project Tracker

> Working agreement: tasks are checked off only when playable/verifiable on device.
> A milestone is done when its **gate** passes, not when its boxes are ticked.
> Parking lot at the bottom — good ideas go there, not into scope.

**Legend:** `[ ]` todo · `[x]` done · `[~]` in progress · `(?)` needs decision first

---

## M0 — Find the Fun (gray-box prototype)

**Gate:** 5 of 7 playtesters voluntarily start a second run. Two failed iterations = pivot/kill review.

### Setup
- [x] Godot 4.x project, portrait 1080×2400 base resolution, Git repo initialized `add-project-scaffold`
- [x] Android export pipeline working (test APK on a real mid-range device) `add-android-export`
- [x] Project structure: `/scenes`, `/scripts`, `/resources/{charms,dice,faces,bosses}`, `/assets` `add-project-scaffold`
- [x] Seeded RNG service (single source of randomness, injectable seed) `add-project-scaffold`

### Spike (timeboxed: 1 week, then decide)
- [x] (?) Spike A: 2D top-down sprite dice with tumble animation curves `add-dice-tumble-spike` *(built, then cut — 3D won)*
- [x] (?) Spike B: 3D dice in SubViewport composited into 2D UI `add-dice-tumble-spike` *(chosen)*
- [x] Perf test both on mid-range Android → **decision logged in PRD §10.1** `add-dice-tumble-spike` *(tested on Pixel 9: 2D 60 / 3D 61 fps; mid-range still unconfirmed — caveat in §10.1)*

### Core throw loop
- [x] Dice bag model: draw N, return/discard rules (tray hard cap: 8) `add-throw-loop`
- [x] **RNG decides all faces before tumble; tumble is presentation only** (architectural law, PRD §6) `add-throw-loop`
- [x] Tumble phase (physics or faked, per spike decision — cosmetic either way) `add-throw-loop` *(3D SubViewport, animation curves, flicker fix applied)*
- [x] Lock Window state machine: 3 windows, frame-rate-independent drain timer, tap-to-lock (with snap-forgiveness radius), force-lock at end `add-throw-loop`
- [x] Focus-loss handling: auto-pause + obscured tray + 3-2-1 resume countdown `add-throw-loop`
- [x] Re-roll of unlocked dice between windows `add-throw-loop`
- [x] Combo detection: **best-single-partition** scoring + GUT unit tests for partition edge cases (quad vs. two pairs, full house vs. triple+pair) `add-scoring`
- [x] Scoring: Pips × Mult × Heat, with placeholder numbers on screen `add-scoring`
- [x] Heat: time-remaining → multiplier conversion (expose curve as tunable) `add-scoring`
- [x] Round loop: target score, 3 throws, win/lose state `add-round-loop`
- [x] Minimal ante climb (3 antes, hardcoded targets) to give runs an arc `add-round-loop`

### Prototype playtest
- [x] Internal: 20 self-runs — lock window 2.5 s feels right, Heat dilemma lands on mid-value boards
- [x] Tune lock window duration — 2.5 s confirmed, no change needed
- [x] **Heat-dilemma test:** lone pair in Window 1 causes genuine hesitation — hypothesis confirmed
- [x] 7 external playtesters (friends, Cristina, colleagues), observed silently
- [x] **GATE REVIEW — PASSED** ✓ All 7 wanted to keep playing; asked if there are roguelike upgrades between antes and requested more satisfying score cascade animation. → Proceed to M1.

---

## M1 — Vertical Slice (one perfect ante)

**Gate:** a stranger can play one full ante unaided and describes it as "satisfying".

### Systems
- [x] Shop scene: charm offers, re-roll, gold economy, interest `add-shop-scene`
- [x] Charm framework: data-driven `.tres` resources + effect hook system (on_lock, on_score, on_window, on_throw) `add-charm-framework`
- [x] 12 launch charms implemented (mix of speed/slow/value/combo archetypes per PRD §4.1) `add-12-charms`
- [ ] Dice materials framework + Bone, Iron, Glass
- [ ] Carving service in shop (face replacement: Wild, Gem, Spark)
- [ ] Trinkets (consumables): re-tumble, freeze timer
- [ ] 1 boss modifier (halved lock windows)
- [ ] Risk round skip mechanic

### Feel & presentation
- [ ] First juice pass: score tick-up audio w/ rising pitch, lock haptics, combo screen shake
- [x] Number cascade animation on scoring `add-score-cascade`
- [ ] Art direction exploration: 3 style frames, pick one
- [ ] UI layout pass: thumb-zone audit on-device
- [ ] Placeholder → first-pass dice/charm art for slice content

### Validation
- [ ] 5 fresh playtesters, no instructions given — log comprehension failures
- [ ] Name decision: shortlist 5, check store collisions + trademark, pick final
- [ ] Start public devlog (juice-pass clips are the marketing asset)
- [ ] **GATE REVIEW**

---

## M2 — Content Complete

**Gate:** feature freeze; full run (6 antes) beatable and losable; all systems in.

- [ ] Full ante curve (6 antes × 3 rounds), exponential target tuning
- [ ] Charm set to 40 (batch in 3 waves: implement → balance → keep/cut)
- [ ] Materials to 6 (add Gold, Echo, Cursed)
- [ ] Carved faces complete (add Bomb, Skull)
- [ ] 8 boss modifiers
- [ ] Meta: collection journal, 5 unlockable bags, 4 seal difficulty tiers
- [ ] Steady Mode (untimed lock windows) + timer-scale setting
- [ ] Accessibility: color-blind palettes, haptics toggle, hand-flip layout
- [ ] Save system: profile JSON + mid-run snapshot/resume
- [ ] Local telemetry: run logs to file (win rate, charm pick rate, throw timings) for balance
- [ ] Headless balance sim: script 1000 seeded bot-runs in CI to flag degenerate combos

---

## M3 — Polish & Balance

**Gate:** beta build sent to 20 testers; crash-free rate > 99%.

- [ ] Audio: commission or license soundtrack (decide PRD §10.7); full SFX pass
- [ ] FX polish: jackpot moments, boss intros, Heat sizzle layer
- [ ] Tutorial: first-run guided ante (skippable)
- [ ] Balance pass from telemetry (target: no charm > 40% pick rate)
- [ ] Localization: EN, DE, ES string extraction + translation
- [ ] Performance: 60 fps verification on low-end device matrix, battery test
- [ ] iOS export pipeline + TestFlight build

---

## M4 — Launch

- [ ] Name decision final (trademark + store search check)
- [ ] Store listings: screenshots, video capture, copy (DE + EN)
- [ ] Web demo build (2 antes) on itch.io
- [ ] Pricing decision + regional pricing
- [ ] PEGI/USK questionnaire (note dice/gambling-adjacency answers)
- [ ] Privacy policy + data safety forms (no data collected — keep it that way)
- [ ] Soft launch (1–2 markets) → fix → worldwide
- [ ] Post-launch week: crash triage on-call

---

## Parking Lot (explicitly NOT in scope)

- Daily seeded runs + leaderboards (needs backend)
- Steam/desktop port
- Endless mode past ante 8
- Charm "foil/negative" rarity variants
- Twitch/streamer integration
- Cloud save sync
