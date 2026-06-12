# LOCKDOWN — Product Requirements Document

**Genre:** Push-your-luck dice roguelike (Balatro-like with real-time pressure moments)
**Platform:** Mobile (iOS + Android), vertical/portrait only
**Engine:** Godot 4.x (GDScript)
**Team:** Solo developer
**Status:** Draft v0.1 — pre-prototype
**Working title:** *Lockdown* (alternates: *Hot Dice*, *Locked In*, *Tumble*, *Snake Eyes*)

---

## 1. Problem Statement

The Balatro-like space is saturated with turn-based card-scoring clones, but no polished title combines run-based engine-building with **real-time reflex moments** — the hybrid exists only as itch.io prototypes. Mobile players who love Balatro's multiplier explosions but also crave flow-state tension have nothing built for them, especially in a one-handed vertical format. Lockdown fills that gap: Yahtzee-readable dice, Balatro-style escalating multipliers, and a 3-second "lock window" that injects adrenaline into every throw.

## 2. Vision & Pillars

A 10–20 minute run where you build a bag of dice and a row of charms that turn modest rolls into screen-shaking jackpots — but every throw demands fast fingers, because dice you don't lock in time get re-rolled out from under you.

**Design pillars (every feature must serve at least one):**

1. **Jackpot payoff** — scoring must escalate visibly and audibly; numbers that climb, chain, and explode.
2. **Flow under pressure** — short, intense lock windows; speed is rewarded, hesitation is a strategy with trade-offs, never a punishment without one.
3. **Readable depth** — anyone who knows dice understands the first minute; synergy discovery carries the next 100 hours.
4. **One thumb, one screen** — fully playable one-handed in portrait; no level design, no map navigation.
5. **Collect & unlock** — every run feeds a visible collection (charms, dice materials, bags, seals).

## 3. Core Loop

### 3.1 Run structure

```
Run = 6 Antes × 3 Rounds (Open / Risk / Boss)
Round = target score, limited Throws
Throw = draw dice from bag → tumble → lock windows → score
```

- A **run** climbs 6 antes; each ante's target score scales exponentially (Balatro pacing, steeper curve to compensate for the shorter ladder).
- Each ante has 3 rounds: **Open** (standard), **Risk** (skippable for reduced reward), **Boss** (modifier rule).
- Each round grants **3 throws** (default) to reach the target. Leftover throws convert to gold.
- Between rounds: **the Shop** (untimed, strategic breathing room).
- Run length target: **12–18 minutes**.

### 3.2 The Throw (the signature mechanic)

1. **Draw**: pull N dice (default 6) from your bag onto the tray.
2. **Tumble**: dice physically tumble across the tray in real time (~1.5 s).
3. **Lock Window 1** (~2.5 s): tap dice to lock them. Timer bar drains.
4. Unlocked dice **re-roll** automatically. **Lock Window 2**, then **Lock Window 3** (everything force-locks at the end of window 3).
5. **Score**: combos detected and scored with full juice cascade.

**Heat (speed bonus):** time remaining across all lock windows converts to a Heat multiplier (e.g., +0–50% Mult). Locking everything in window 1 is the adrenaline play; waiting for re-rolls is the gambler's play. Both must be viable builds.

> **Central design hypothesis (M0 must answer this):** locking *good* dice early is already optimal — Heat only creates a real decision on mid-value boards (a lone pair in Window 1: bank it fast, or gamble the rest?). The Heat curve must be tuned until mid-boards feel genuinely agonizing. If no tuning makes that dilemma land, the mechanic — and the game — pivots.

**Tray cap:** max **8 dice** on the tray, hard limit (readability + tap precision). Draw-size charms respect the cap.

### 3.3 Scoring model

`Score = (Pips + Bonus Chips) × (Combo Mult + Charm Mult) × Heat`

Base combos (tunable):

| Combo | Example | Base |
|---|---|---|
| Pair | 4-4 | low |
| Two Pair | 2-2 / 5-5 | low-mid |
| Triple | 6-6-6 | mid |
| Small Straight | 1-2-3-4 | mid |
| Full House | 3-3-3 / 5-5 | mid-high |
| Quad | 4× same | high |
| Large Straight | 1–6 | high |
| Quint+ | 5–6× same | jackpot |

Only **locked** dice score. Scoring uses the **best single partition** rule: each locked die belongs to exactly one combo, and the highest-scoring partition of the locked set is chosen automatically. (Charms may break this rule deliberately — e.g., "Double Dip: pairs also score inside larger combos" — making rule-breaking a reward, not a default.)

### 3.4 Economy & Shop

- Earn **gold** per round (base + leftover throws + interest on savings, capped).
- Shop offers (re-rollable for gold):
  - **Charms** (max 5 slots) — the Joker analog; passive scoring/rule modifiers.
  - **Dice** — add a die to your bag (materials matter, see 4.2).
  - **Carving** — permanently modify one face of one die (the deck-editing analog).
  - **Trinkets** (max 2) — one-shot consumables (e.g., "re-tumble", "freeze timer", "duplicate a die").
  - **Bag tweaks** — remove a die, shrink/grow draw size.

## 4. Game Systems

### 4.1 Charms (initial set: 40 at launch; 12 for vertical slice)

Examples spanning build archetypes:

- **Quick Draw** — ×2 Mult if all locks happen in Window 1. *(speed build)*
- **Patient Zero** — dice locked in Window 3 score double Pips. *(slow build — deliberate counter-archetype)*
- **Snake Charmer** — a pair of 1s gives ×4 Mult instead of scoring low. *(inversion)*
- **Loaded** — all 6s count as 12 Pips. *(value)*
- **Collector** — +2 Mult per distinct pair locked. *(combo-stacker)*
- **Magnet** — the first die you lock pulls all matching faces to lock with it. *(reflex amplifier)*
- **Overheat** — Heat can exceed 100%, but a fully drained timer breaks a random charm. *(risk)*
- **Echo Chamber** — Echo dice copy the highest adjacent locked face. *(material synergy)*

### 4.2 Dice materials (6 at launch; 3 for vertical slice)

- **Bone** (standard) — baseline.
- **Iron** — tumbles slower (easier to read), −1 Pip on every face.
- **Glass** — shatters if re-rolled (lock it in Window 1 or lose it for the round), ×2 Pips.
- **Gold** — earns 1 gold when locked, low faces.
- **Echo** — blank faces; copies a neighbor when locked.
- **Cursed** — high faces, but locks itself randomly in Window 1.

### 4.3 Carved faces

Replace a pip face with: **Wild** (any value), **Gem** (+20 Chips), **Spark** (+0.5 s to next window), **Bomb** (re-tumbles all unlocked dice), **Skull** (counts as 0, ×1.5 Mult to the throw).

### 4.4 Boss modifiers (8 at launch; 2 for vertical slice)

Examples: lock windows halved; 1s become blanks; must lock ≥3 dice in Window 1; Heat disabled; bag shuffles mid-round; target score hidden until Throw 2.

### 4.5 Meta progression

- **Collection journal** — every charm/die/face discovered is logged (Balatro-style completion pull).
- **Bags** (starting loadouts; deck analog) — unlocked by win conditions (e.g., "win with no Glass dice").
- **Seals** (difficulty stakes) — stacking modifiers for post-win replay.
- No gameplay-relevant grind: unlocks expand *variety*, never raw power.

### 4.6 Accessibility (non-negotiable)

- **Steady Mode**: lock windows untimed; Heat is fixed at the **population-average value** (start ×1.25, tune from telemetry) so accessibility players face the same ante curve with equal expected scoring — equal outcomes, different inputs.
- Timer scale option (0.75×–1.5×), color-blind-safe palettes, haptics toggle, left/right hand layout flip.

## 5. UX / Presentation

- **Layout (portrait):** top = ante/target/score readout; middle 50% = physics tumble tray; bottom = charm row, bag counter, throw button. All interactive elements in thumb reach.
- **Interruption policy (P0):** on focus loss (call, notification, app switch) the game auto-pauses AND obscures the tray (blur/cover) to prevent pause-scumming; resume runs a 3-2-1 countdown. A backgrounded lock window restores to the start of that window with a full timer — generous beats fragile.
- **Tap forgiveness:** dice at rest are ≥ 48 dp with spacing; taps snap to the nearest unlocked die within a forgiveness radius. A distinct haptic fires when a lock window is about to expire (peripheral-attention channel while eyes track dice).
- **Juice (P0, not polish):** research on Balatro shows the feedback loop *is* the product — synced score-tick audio rising in pitch, screen shake on combo thresholds, number cascade animations, haptic pulses on lock. Budget juice as a first-class milestone, not an afterthought.
- **Art direction:** to be explored in M1 — candidate: "back-alley dice den" — felt textures, neon signage accents, CRT-adjacent grain. Must stay readable at high speed.
- **Audio:** lock taps as percussive notes; scoring cascade as a rising arpeggio; Heat bonus as a sizzle layer.

## 6. Technical Architecture

- **Engine:** Godot 4.x, GDScript. Rationale: best-in-class for solo 2D mobile; Luck Be a Landlord (closest structural cousin) shipped mobile on Godot.
- **Dice rendering:** Decision needed at M0 — (a) 2D top-down sprites with tumble animation (cheap, readable) vs. (b) 3D dice in a SubViewport composited into the 2D UI (gorgeous, heavier). Prototype both in week 1; pick by feel + perf on mid-range Android.
- **Data-driven content:** charms, dice, faces, bosses as Godot `Resource` files (`.tres`) — enables Claude Code to add/balance content without touching engine code.
- **Determinism (architectural law):** the seeded RNG decides every die face *before* the tumble begins; the tumble is pure presentation animating to a predetermined result. Physics must never determine outcomes (Godot physics is not reproducible across devices/frame rates) — this preserves seeded runs, enables the headless balance sim, and keeps daily runs (P2) possible. Lock-window timers accumulate `delta` in `_process` (frame-rate independent), never count frames or physics steps.
- **Save system:** JSON profile (collection, unlocks, settings) + mid-run snapshot save.
- **Targets:** 60 fps on a 2021 mid-range Android; cold start < 3 s; binary < 150 MB.
- **No backend for v1.** Leaderboards/daily runs are P2.

## 7. Monetization & Distribution

- **Premium, one-time purchase** (~€5–8), no ads, no IAP — the proven model in this exact niche (Slice & Dice, Luck Be a Landlord) and a marketing differentiator on mobile.
- Free **web demo** (Godot HTML5 export, first 2 antes) on itch.io for feedback + wishlist funnel.
- Steam (desktop) port is P2 — architecture should not preclude it (keep input abstraction touch/mouse agnostic).

## 8. Goals & Success Metrics

**Prototype gate (M0):** 5 of 7 playtesters voluntarily start a second run without being asked. If this fails twice after iteration, pivot or kill — the lock-window mechanic must be fun gray-boxed.

**Leading indicators (beta):**
- Median session ≥ 15 min; ≥ 40% of sessions include 2+ runs.
- Run completion (win or loss reached, not abandoned) ≥ 70%.
- Steady Mode usage tracked (validates accessibility investment).

**Lagging indicators (launch +60 days):**
- ≥ 4.5 store rating; D7 retention ≥ 20% (premium-game benchmark).
- Break-even on direct costs (store fees, assets, music licensing) — success threshold; stretch: fund the next game.

## 9. Non-Goals (v1)

- **No multiplayer / PvP** — entirely different balance and netcode problem; revisit only if v1 succeeds.
- **No procedural levels, maps, or narrative campaign** — the run structure *is* the content; pillar 4.
- **No free-to-play economy** — undermines trust positioning and doubles design surface.
- **No live-ops content cadence commitments** — solo dev; updates ship when ready.
- **No tablet/landscape-optimized layout for v1** — portrait phone first; tablets get letterboxed portrait.

## 10. Risks & Open Questions

| # | Question | Type | Owner | Blocking? |
|---|---|---|---|---|
| 1 | 2D sprite dice vs. 3D SubViewport dice | Tech/feel | Prototype week 1 | Yes (M0) |
| 2 | Is the lock window fun, or stressful in a bad way? | Design | M0 playtest | Yes (M0) |
| 3 | Heat formula: additive Mult vs. multiplicative? | Balance | M1 tuning | No |
| 4 | Name: "Lockdown" carries pandemic connotation + title collisions — rename? | Brand | End of M1 (affects art direction) | No |
| 5 | Physics tumble on low-end Android — fake it with animation curves? | Tech | M0 perf test | No |
| 6 | EU consumer law / PEGI rating re: dice imagery (gambling adjacency) | Legal | Before launch | No |
| 7 | Music: license vs. commission (Balatro proves the soundtrack matters) | Production | M3 | No |

## 11. Milestones (detail in TASKS.md)

> **Effort assumption:** this is a nights-and-weekends project at **~8–10 focused hours/week** alongside a full-time job. Durations below are *effort* estimates; calendar time is roughly 3× (realistic launch horizon: 12–14 months). Milestones complete when gates pass, not when calendars say so.

| Milestone | Outcome | Gate |
|---|---|---|
| **M0 — Find the Fun** (~25–35 h) | Gray-box throw loop: tumble, lock windows, scoring, Heat | Prototype gate (§8) **+ Heat-dilemma hypothesis answered (§3.2)** |
| **M1 — Vertical Slice** (~50–70 h) | One full ante: shop, 12 charms, 3 materials, 1 boss, first juice pass; start public devlog; **name decision** | "Looks like the game" |
| **M2 — Content Complete** (~80–100 h) | 6 antes, 40 charms, 6 materials, 8 bosses, meta progression, Steady Mode | Feature freeze |
| **M3 — Polish & Balance** (~50 h) | Audio, FX, tutorial, balance from telemetry, localization (EN/DE/ES); validate web-demo audio latency early | Beta build |
| **M4 — Launch** (~30 h) | Store builds, web demo, page assets, soft launch | Ship |
