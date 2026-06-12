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
- [ ] Android export pipeline working (test APK on a real mid-range device)
- [x] Project structure: `/scenes`, `/scripts`, `/resources/{charms,dice,faces,bosses}`, `/assets` `add-project-scaffold`
- [x] Seeded RNG service (single source of randomness, injectable seed) `add-project-scaffold`

### Spike (timeboxed: 1 week, then decide)
- [ ] (?) Spike A: 2D top-down sprite dice with tumble animation curves
- [ ] (?) Spike B: 3D dice in SubViewport composited into 2D UI
- [ ] Perf test both on mid-range Android → **decision logged in PRD §10.1**

### Core throw loop
- [ ] Dice bag model: draw N, return/discard rules (tray hard cap: 8)
- [ ] **RNG decides all faces before tumble; tumble is presentation only** (architectural law, PRD §6)
- [ ] Tumble phase (physics or faked, per spike decision — cosmetic either way)
- [ ] Lock Window state machine: 3 windows, frame-rate-independent drain timer, tap-to-lock (with snap-forgiveness radius), force-lock at end
- [ ] Focus-loss handling: auto-pause + obscured tray + 3-2-1 resume countdown
- [ ] Re-roll of unlocked dice between windows
- [ ] Combo detection: **best-single-partition** scoring + GUT unit tests for partition edge cases (quad vs. two pairs, full house vs. triple+pair)
- [ ] Scoring: Pips × Mult × Heat, with placeholder numbers on screen
- [ ] Heat: time-remaining → multiplier conversion (expose curve as tunable)
- [ ] Round loop: target score, 3 throws, win/lose state
- [ ] Minimal ante climb (3 antes, hardcoded targets) to give runs an arc

### Prototype playtest
- [ ] Internal: 20 self-runs, note where boredom/frustration hits
- [ ] Tune lock window duration (test 2.0 / 2.5 / 3.0 s)
- [ ] **Heat-dilemma test:** engineer mid-value boards (lone pair, Window 1) — do testers visibly hesitate? Tune Heat curve until they do
- [ ] 7 external playtesters (friends, Cristina, colleagues), observe silently
- [ ] **GATE REVIEW** — record result + decision (replay rate AND Heat-dilemma verdict)

---

## M1 — Vertical Slice (one perfect ante)

**Gate:** a stranger can play one full ante unaided and describes it as "satisfying".

### Systems
- [ ] Shop scene: charm offers, re-roll, gold economy, interest
- [ ] Charm framework: data-driven `.tres` resources + effect hook system (on_lock, on_score, on_window, on_throw)
- [ ] 12 launch charms implemented (mix of speed/slow/value/combo archetypes per PRD §4.1)
- [ ] Dice materials framework + Bone, Iron, Glass
- [ ] Carving service in shop (face replacement: Wild, Gem, Spark)
- [ ] Trinkets (consumables): re-tumble, freeze timer
- [ ] 1 boss modifier (halved lock windows)
- [ ] Risk round skip mechanic

### Feel & presentation
- [ ] First juice pass: score tick-up audio w/ rising pitch, lock haptics, combo screen shake
- [ ] Number cascade animation on scoring
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
