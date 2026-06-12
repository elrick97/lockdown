# CLAUDE.md — Lockdown

Mobile dice roguelike (Balatro-like with real-time lock windows). Solo dev project.
Read `PRD.md` for the full design; `TASKS.md` is the single source of truth for work status.

## Working rules

- **This project uses OpenSpec (OPSX) for spec-driven development.** No non-trivial code is written without an OpenSpec change. Workflow per feature: `/opsx:propose` → review proposal → specs/design → `tasks.md` → `/opsx:apply` → verify on device → `/opsx:archive`.
- **Hierarchy of truth:**
  1. `openspec/specs/` — living specification of how the game currently works (merged from archived changes). When code and spec disagree, the spec wins or must be amended via a change.
  2. `PRD.md` — product intent and design pillars. Changes must trace back to a PRD section; if they don't, flag it.
  3. `TASKS.md` — the macro roadmap (milestones + gates). Each checklist item maps to one OpenSpec change (kebab-case name noted next to the item when started).
- **Granularity:** one OpenSpec change ≈ one TASKS.md checkbox (e.g., `lock-window-state-machine`, `charm-effect-hooks`). Never bundle unrelated systems into one change.
- **Respect milestone gates.** Do not start M(n+1) changes before the M(n) gate review is logged in TASKS.md.
- **Design pillars veto features** (PRD §2): jackpot payoff, flow under pressure, readable depth, one thumb one screen, collect & unlock. A proposal that serves none of them should be rejected at the proposal stage — that's the cheapest place to kill it.
- **Never skip the human review between artifacts.** Proposal, specs/design, and tasks each get explicit approval before proceeding. Don't auto-fast-forward through all artifacts in one sitting on gameplay-critical systems (scoring, Heat, lock windows); batching artifacts is acceptable for plumbing (save system, settings, export pipeline).
- **Archive discipline:** a change is archived only after its tasks are verified on the Android test device. Archiving merges spec deltas into `openspec/specs/` — stale unarchived changes are tech debt; flag them.

## Tech stack & conventions

- **Godot 4.x, GDScript.** Static typing everywhere (`var x: int`, typed function signatures).
- Portrait-only, base resolution 1080×2400, `canvas_items` stretch mode.
- **Content is data, not code:** charms, dice, faces, and bosses are `Resource` (`.tres`) files under `res://resources/`. Adding a charm must never require editing the scoring engine — use the effect hook system (`on_lock`, `on_score`, `on_window`, `on_throw`).
- **All randomness flows through `RngService`** (seeded per run). Never call `randi()` directly.
- Scene structure: one scene per screen (`Run`, `Shop`, `Collection`, `Settings`); throw loop lives in `Run` as a state machine (`Draw → Tumble → Lock1 → Reroll → Lock2 → Reroll → Lock3 → Score`).
- Signals over direct node references for cross-system communication.

## Project structure

```
/openspec
  config.yaml  # tech stack + project context for OPSX
  /specs       # living spec — current truth of all shipped systems
  /changes     # active change folders (proposal, design, specs deltas, tasks)
/scenes        # .tscn screens and reusable components
/scripts       # GDScript, mirrors /scenes naming
/resources
  /charms      # one .tres per charm
  /dice        # materials
  /faces       # carved faces
  /bosses      # boss modifiers
/assets        # art, audio (git-lfs)
/tools         # balance sim, telemetry parser (Python ok here)
```

## Spec-writing conventions (OpenSpec)

- Spec requirements use testable SHALL statements with Given/When/Then scenarios (e.g., "Given Window 1 is active, when the timer reaches zero, the system SHALL re-roll all unlocked dice and open Window 2").
- Game-feel parameters (timer durations, Heat formula, ante curves) live in specs as **named tunables with current values**, so balance changes are spec deltas, not silent edits.
- Content additions (new charms/dice/bosses) within an already-specced framework do NOT need a change proposal — only framework/rule changes do. Content goes through the balance sim instead.

## Testing & verification

- GUT (Godot Unit Test) for: combo detection, scoring math, charm effects, RNG determinism (same seed → same run).
- Balance sim in `/tools`: headless seeded bot-runs; run before merging any charm/balance change.
- "Verified" means: ran on the Android test device, not just in-editor.

## Things Claude should NOT do

- No new dependencies/plugins without asking.
- No placeholder TODOs left in merged code — finish or file a task.
- No touching `Heat` or ante target curves without running the balance sim and reporting before/after numbers.
- Never commit secrets/keystore files; release signing is manual.
