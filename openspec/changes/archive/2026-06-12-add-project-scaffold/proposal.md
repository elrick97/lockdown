# Proposal: add-project-scaffold

## Why

Nothing can be built or playtested until a Godot project exists with the agreed structure, and M0's central hypothesis (the Heat dilemma) depends on seeded, reproducible runs — so the RNG service must be the first code written, not retrofitted. This change covers the first two checkboxes of M0 Setup in TASKS.md.

**Pillars served (PRD §2):** none directly — this is enabling infrastructure for all five. The seeded RNG specifically enables *readable depth* (reproducible balance tuning) and the future daily-run feature.

## What Changes

- New Godot 4.6 project: portrait orientation, 1080×2400 base resolution, `canvas_items` stretch mode, GDScript with static typing.
- Folder structure created: `/scenes`, `/scripts`, `/resources/{charms,dice,faces,bosses}`, `/assets`, `/tools`.
- `RngService` autoload: the single source of randomness for all gameplay. Injectable seed, derivable sub-streams, headless-safe.
- GUT test framework installed and wired so `godot_console --headless` runs the suite from CLI (CI-ready).
- Smoke test proving determinism: same seed → same sequence of die faces.

## Capabilities

### New Capabilities
- `project-structure`: Godot project configuration (display, orientation, stretch) and the canonical folder layout content must follow.
- `seeded-rng`: deterministic, injectable-seed randomness service that all gameplay code must use; physics and presentation never influence outcomes.

### Modified Capabilities

_None — first change in the repo._

## Impact

- New files only; no existing code affected (there is none).
- Adds GUT as the project's first addon dependency (test-only, already sanctioned by TASKS.md M0 and CLAUDE.md testing conventions).
- Unblocks every subsequent M0 change (`add-throw-loop`, `add-scoring`, `add-round-loop`) and the week-1 rendering spike.

## Non-goals

- No Android export pipeline (separate TASKS.md item; needs device testing).
- No dice, throw loop, scoring, or any gameplay — gray-box content comes in the next changes.
- No art, audio, or UI beyond an empty main scene that boots.
- No save system, no telemetry.
