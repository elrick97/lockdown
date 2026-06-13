## Context

The throw loop (ThrowController + ScoringEngine) is complete and verified. Each throw produces a `ScoreBreakdown` with a `final_score`. What's missing is anything that gives that score meaning: a target to beat, a throw budget, and a sense of run-wide progression. Without these the game session has no win/lose state and the M0 gate playtest cannot happen.

The PRD specifies: Run = 6 Antes × 3 Rounds; Round = target score + 3 throws. M0 collapses this to 3 antes × 1 round each (no Open/Risk/Boss split, no Shop) — the minimum arc that makes the session feel like a game rather than a series of isolated throws.

## Goals / Non-Goals

**Goals:**
- `RoundState`: pure headless `RefCounted` — tracks throw budget and running total; emits win/lose signals
- `AnteArc`: tracks the 3-ante progression and emits run-end signals
- Ante targets live in a `.tres` resource so M0 balance tuning is a file edit
- Throw scene wired to both: shows ante N/3, throw N/3, running total / target, THROW AGAIN / ANTE CLEARED / GAME OVER
- GUT-testable round transitions (win early, lose on 3rd throw, ante advance, run end)

**Non-Goals:**
- Open / Risk / Boss round types (M1)
- Shop between rounds (M1)
- Gold economy (M1)
- Leftover-throw-to-gold conversion (M1)
- Animated score tick or combo screen shake (M1)
- Save/resume mid-run (M2)
- Difficulty scaling beyond 3 hardcoded antes (M2 full curve)

## Decisions

### 1. RoundState is a pure RefCounted, not an autoload

**Decision:** `RoundState extends RefCounted`. Created by the scene (or test) with a target and throw-cap.

**Why:** Mirrors `ThrowController` — headless-safe, injectable, no scene tree dependency. The balance sim and GUT tests can drive it without a scene. A singleton autoload would couple round logic to Godot's node lifecycle and make headless testing awkward.

**Alternative considered:** `extends Node` autoload. Rejected — same pattern as ThrowController; the prior change proved RefCounted is the right level here.

### 2. AnteArc holds hardcoded targets in a Resource

**Decision:** `AnteArc extends RefCounted`; constructed with an `AnteConfig` Resource that carries the array of target scores. Default `resources/ante_arc.tres` holds M0 values (`[150, 350, 700]`).

**Why:** Keeps targets as named data (spec-visible tunables), not magic numbers in code. Balance changes during M0 playtest are a `.tres` edit, not a code change — consistent with `ThrowConfig` and `ScoringConfig`. The full 6-ante curve in M2 replaces `ante_arc.tres`; no code change needed.

**Alternative considered:** Constants in `AnteArc` script. Rejected — violates the data-not-code principle and makes balance deltas invisible to spec diffs.

### 3. Score accumulates across throws within a round

**Decision:** `RoundState` accumulates `_total` across all throws in the round. A round is won the moment `_total >= target`, which can happen mid-round (after throw 1 or 2). On throw 3 completion, if target not yet met, round is lost.

**Why:** PRD §3: "3 throws per round to reach target." Cumulative scoring means a mediocre throw 1 can be recovered by a great throw 2 — the push-your-luck tension carries across throws, not just within one.

**Alternative considered:** Each throw scored independently, best-of-3. Rejected — eliminates the cross-throw recovery tension that is central to the push-your-luck loop.

### 4. No inter-ante pause screen in M0

**Decision:** After an ante is cleared, the scene shows "ANTE N CLEARED — THROW TO CONTINUE" and pressing THROW starts the next ante's first throw.

**Why:** M0's only goal is to verify the lock-window mechanic is fun. A shop screen would add scope without adding to the core question. A single continue button keeps the playtest focused on the throw loop, not economy decisions.

### 5. Throw scene is the orchestrator in M0

**Decision:** `throw_scene.gd` owns the `RoundState` and `AnteArc` instances and sequences them. Signals from both drive label updates in the scene.

**Why:** M0 has one scene. Introducing a separate RunController scene for one scene is premature. When M1 adds the Shop scene, a RunController can be extracted then — the logic boundary is already clean (RoundState and AnteArc are pure RefCounted).

## Risks / Trade-offs

- **[Balance]** Hardcoded targets (150 / 350 / 700) are placeholders; M0 playtest will require tuning. Mitigation: targets in `.tres` — rebalance without touching code.
- **[Scope creep]** The natural impulse is to add a score animation, a win screen, or between-ante text. Mitigation: spec strictly says "gray-box text labels" — any polish is explicitly M1.
- **[M1 extraction]** The throw scene will become crowded when Shop is added. Mitigation: RoundState and AnteArc are already pure RefCounted — they lift out cleanly into a RunController with no refactor of their internals.
