# LOCKDOWN — PRD Review Panel (Round 1)

**Date:** 2026-06-12 · **Document reviewed:** PRD.md v0.1
**Severity key:** 🔴 P0 = fix before building · 🟡 P1 = fix during M0/M1 · ⚪ P2 = note for later

---

## Reviewer 1 — Roguelike Systems Designer (Balatro/LBaL-class games)

**Verdict: APPROVE WITH CHANGES** — the substrate is fresh and the pillar structure is sound, but two scoring-system holes would surface in week one of prototyping.

**Strengths**
- The bag/dice/charm three-layer build system mirrors what makes Balatro deep (deck edits + Jokers) without copying poker. The Carving system is the sleeper hit — face-level deck editing is more granular than Balatro's card edits.
- Counter-archetype charms (Quick Draw vs. Patient Zero) show the designer already understands that Heat must not collapse into one dominant strategy.
- Glass dice are excellent: material properties that interact with the timing mechanic, not just stats.

**Issues**
- 🔴 **D1 — Combo stacking is undefined.** "Multiple combos in one lock-set all score" is ambiguous: does 4-4-4-4 score as a Quad + a Triple + three Pairs? If yes, scoring explodes combinatorially and Quint balance is impossible; if no, the rule isn't written. **Fix:** score the *best single partition* of locked dice (each die counts once); sell rule-breaking as charm design space ("Double Dip: pairs also count inside larger combos").
- 🔴 **D2 — The core tension is asserted, not designed.** Why rush? Locking good dice early is already optimal (protects them from re-roll); Heat just pays you extra for what you'd do anyway. The *dilemma* only exists on mid-value boards (e.g., a pair of 3s in Window 1). The Heat curve must be tuned so mid-boards are genuinely agonizing — this is THE question M0 must answer, and the PRD should name it as the prototype's central hypothesis, not bury it.
- 🟡 **D3 — Run-length math doesn't close.** 8 antes × 3 rounds × ~3 throws (~15 s each) + 8 shops ≈ 25+ minutes, over the 12–18 min target. **Fix:** 6 antes, keep exponential curve steeper.
- 🟡 **D4 — "Hoarder" (+1 die drawn) fights the screen.** Dice count needs a hard cap (8) or charms like this destroy readability and tap precision.
- ⚪ **D5 —** "Target score hidden" boss is information denial, which tends to feel arbitrary rather than challenging. Replace with a pressure modifier (e.g., target grows 5% per second of hesitation — on-theme).
- ⚪ **D6 —** Cursed dice "lock themselves randomly" removes agency in the one moment the game is about agency. Rework: Cursed locks itself *if you haven't locked anything yet* — preserves theme, restores counterplay.

---

## Reviewer 2 — Mobile UX & Accessibility Specialist

**Verdict: APPROVE WITH CHANGES** — vertical one-thumb framing is right and rare; two real-time-on-mobile realities are unhandled.

**Strengths**
- Portrait one-handed as a *pillar*, not an afterthought, is the correct call for the commute use case and a genuine market differentiator.
- Steady Mode existing at all puts this ahead of most reflex-adjacent games.

**Issues**
- 🔴 **U1 — Interruption policy is missing.** Phones get calls, notifications, and pocket-locks mid-lock-window. Without a rule, either players lose throws unfairly (rage) or backgrounding becomes pause-scumming (cheese: background the app to study the board). **Fix:** on focus loss, auto-pause AND obscure the tray (blur/cover); resume with a 3-2-1 countdown. Timer state must serialize with the mid-run snapshot.
- 🔴 **U2 — Steady Mode as specced punishes the players it serves.** Heat fixed at ×1.0 means accessibility users score strictly less and will hit ante walls the game wasn't balanced for. **Fix:** Steady Mode fixes Heat at the population-average value (start at ×1.25, tune from telemetry). Equal outcomes, different inputs.
- 🟡 **U3 — Tap targets during excitement.** Dice at rest must be ≥ 48 dp with spacing; mis-taps in a 2.5 s window are guaranteed otherwise. Add "tap-anywhere-near snaps to nearest unlocked die" forgiveness radius. Test with thumb, on device, standing on a U-Bahn.
- 🟡 **U4 — First-session timer anxiety.** Cold-open players facing a draining bar churn. The tutorial ante should run lock windows at 1.5× duration and say so ("training wheels off next round").
- ⚪ **U5 —** Haptics on lock are specced — good — but add a distinct haptic for *window about to expire* (the peripheral-attention channel matters when eyes are on dice).

---

## Reviewer 3 — Technical Reviewer (Godot, solo-dev mobile)

**Verdict: APPROVE WITH CHANGES** — stack choice is right; one architectural decision must be reversed before any code exists.

**Strengths**
- Data-driven `.tres` content + effect hooks is exactly how to make a 40-charm game maintainable solo, and it makes the headless balance sim feasible.
- Budgeting juice as P0 matches the evidence on why Balatro works.

**Issues**
- 🔴 **T1 — Physics must not determine roll outcomes.** The PRD implies dice "tumble" then show results. If physics decides the face, seeded determinism is dead (Godot physics is not reproducible across devices/frame rates), the balance sim can't exist, and daily runs (P2) are forfeit. **Fix (architectural law):** the seeded RNG decides every face *before* the tumble; the tumble is pure presentation that animates to a predetermined result. This also resolves spike A vs. B — both options become cosmetic choices.
- 🟡 **T2 — Lock-window timers must be frame-rate independent** (accumulate `delta`, never count frames) and must tick in `_process`, not physics steps, or low-end devices get shorter effective windows. Add a device-clock test to GUT.
- 🟡 **T3 — Mid-run snapshot + real-time state.** Serializing "between throws" only is fine and much simpler than mid-window saves; spec that explicitly (a backgrounded lock window restores to the start of that window, full timer — generous beats fragile).
- ⚪ **T4 —** HTML5 demo export: Godot web builds have audio-latency quirks; since audio-score sync is core to the juice, validate the web demo's feel early in M3, not at M4.

---

## Reviewer 4 — Production & Market Analyst

**Verdict: APPROVE WITH CHANGES** — differentiation thesis is validated; the schedule is the risk.

**Strengths**
- Market gap is real: Balatro-likes are saturated *within* turn-based scoring; the hybrid real-time niche has no polished mobile occupant. The "Beyond Words" precedent (Balatro × Scrabble, well received) validates substrate-swapping as a strategy.
- Premium/no-IAP matches the proven monetization of the two closest comparables (Slice & Dice, Luck Be a Landlord) and is a trust signal in store copy.
- The M0 kill-gate ("5 of 7 replay unprompted, two failures = pivot") is unusually disciplined for a passion project. Keep it.

**Issues**
- 🔴 **P1 — The timeline has no hours assumption.** "2–3 weeks" for M0 reads as full-time, but this is a nights-and-weekends project alongside a demanding day job. At ~8–10 focused hrs/week, the real calendar is roughly 3× the listed durations (launch ≈ 12–14 months, not ~5). Unstated, this guarantees demoralization at M1. **Fix:** state the hours assumption in the PRD and let milestones be effort-based, not calendar-based.
- 🟡 **P2 — Name risk is underweighted.** "Lockdown" has pandemic baggage *and* collides with existing game titles; in DACH stores discoverability will suffer. Move the rename decision from "before store listing" to end of M1 — branding affects art direction.
- 🟡 **P3 — Wishlist/funnel work isn't scheduled.** The itch.io demo at M4 is too late to build an audience. Add a lightweight devlog start at M1 (screenshots of the juice pass are the marketing asset).
- ⚪ **P4 —** German market note: dice + "gambling-adjacent" imagery is fine for USK with no real-money element, but answer the store questionnaires conservatively; the PRD's open question #6 is correctly flagged.

---

## Consolidated Panel Decision

**READY TO BUILD after P0 fixes — no pivot required.** The idea survives review: the lock-window mechanic is a defensible differentiator, the systems design has Balatro-grade depth potential, and the comparables validate platform + pricing. The P0s are all fixable on paper before a line of code:

| # | Fix | Status |
|---|---|---|
| D1 | Best-single-partition combo rule | ✅ Applied to PRD §3.3 |
| D2 | Heat dilemma named as M0's central hypothesis | ✅ Applied to PRD §3.2 + §8 |
| D3 | 6 antes (run-length math) | ✅ Applied to PRD §3.1 |
| T1 | RNG decides faces; tumble is presentation only | ✅ Applied to PRD §6 |
| U1 | Focus-loss pause + obscured tray + countdown | ✅ Applied to PRD §5 |
| U2 | Steady Mode Heat = population average | ✅ Applied to PRD §4.6 |
| P1 | Effort-based timeline w/ hours assumption | ✅ Applied to PRD §11 |
| D4/U3 | Dice cap (8) + tap forgiveness | ✅ Applied to PRD §3.2/§5 |

P1/P2 items folded into TASKS.md and PRD open questions. Recommend Round 2 review after the M0 prototype exists — paper review can't answer D2; only thumbs on glass can.
