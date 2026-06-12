# Tasks: add-project-scaffold

## 1. Godot project shell

- [ ] 1.1 Create `project.godot` (Godot 4.6): name, main scene, portrait 1080×2400, `canvas_items` stretch + `expand` aspect, orientation locked to portrait
- [ ] 1.2 Create folder layout: `/scenes`, `/scripts`, `/resources/{charms,dice,faces,bosses}`, `/assets`, `/tools` (with `.gitkeep`s and `/tools/.gdignore`)
- [ ] 1.3 Minimal `scenes/main.tscn` that boots to a blank screen; verify project opens and runs in the editor

## 2. Seeded RNG service

- [ ] 2.1 `scripts/rng_core.gd` (`RngCore`, `RefCounted`): run seed (explicit or generated+retrievable), lazy named streams via `hash(seed, stream_name)`, typed API (`randi_range`, `randf`, `shuffle`)
- [ ] 2.2 `scripts/rng_service.gd` autoload wrapping `RngCore`; register in `project.godot`; document canonical stream names (`dice`, `shop`, `bag`)

## 3. Test infrastructure

- [ ] 3.1 Install GUT under `addons/gut/`, enable plugin, create `/tests` with GUT config
- [ ] 3.2 `tools/run_tests.ps1` invoking `godot_console.exe --headless` with the GUT CLI runner; non-zero exit on failure
- [ ] 3.3 Determinism tests for `RngCore`: same seed → same sequence; stream independence (shop draws don't shift dice stream); generated seed reproduces run
- [ ] 3.4 Run the suite headless from a fresh shell and confirm exit codes (0 on pass, non-zero with a forced failing test)

## 4. Wrap up

- [ ] 4.1 Update TASKS.md: tick "Godot 4.x project…" and "Seeded RNG service" boxes, note change name `add-project-scaffold` next to them
- [ ] 4.2 Commit
