# Design: add-project-scaffold

## Context

Empty repo (docs only). Godot 4.6.3 is installed at `C:\Tools\Godot` with the console binary available for headless runs. This change creates the project shell every later change builds on; the only real design surface is the RNG service, because determinism is an architectural law (PRD §6) that cannot be retrofitted cheaply.

## Goals / Non-Goals

**Goals:**
- A bootable, committed Godot project matching the agreed display config and folder layout.
- `RngService` good enough that no later change ever needs to touch its API (seed in, streams out).
- Headless test execution proven now, while the project is trivial — not debugged later under pressure.

**Non-Goals:**
- Android export, gameplay, UI, save system (later changes).
- A general utility library — only what the scaffold needs.

## Decisions

**D1 — `RngService` as autoload wrapping per-stream `RandomNumberGenerator` instances.**
Each named stream (`dice`, `shop`, `bag`) gets its own `RandomNumberGenerator` seeded with `hash(run_seed, stream_name)`. Godot's RNG (PCG32) is deterministic across platforms for a given seed, satisfying device-independence without custom PRNG code.
*Alternative considered:* one shared RNG with manual call ordering — rejected; any reordered call silently desyncs seeded runs, and the bug class is undetectable in playtests.

**D2 — Streams created lazily by name, the three canonical names documented as constants.**
Keeps the API open for later systems (e.g., a `boss` stream in M2) without an enum migration.

**D3 — GUT installed under `addons/gut/` and committed to the repo (not a submodule or asset-library fetch at build time).**
Solo dev + reproducible CI beats repo size concerns; GUT is small.
*Alternative considered:* gdUnit4 — viable, but GUT is the TASKS.md assumption and the de-facto standard with better headless documentation.

**D4 — `.gdignore` in `/tools`** so Godot's importer never scans Python balance-sim code.

**D5 — Folder placeholders via `.gitkeep`.** Git can't track empty dirs; placeholder scenes would be noise.

## Risks / Trade-offs

- [Godot minor-version upgrades could change RNG sequences] → Pin the Godot version in `project.godot` config notes; treat engine upgrades as a change proposal with a determinism re-test.
- [GUT major versions occasionally change CLI flags] → Pin the committed GUT version; the headless invocation lives in one script (`tools/run_tests.ps1`) so a flag change is a one-line fix.
- [Autoload singletons complicate pure-headless unit tests] → `RngService` keeps all logic in a plain `RefCounted` class (`RngCore`); the autoload is a thin wrapper. Tests target `RngCore` directly.

## Open Questions

- None blocking. Stream-name registry growth is deferred to the change that needs it.
