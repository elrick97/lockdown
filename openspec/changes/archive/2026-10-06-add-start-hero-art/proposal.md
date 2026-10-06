## Why

The start screen is the first thing a player sees, and its mark was flat vector line art (a die outline and a bolt drawn with `draw_rect` and polygons). It was the last flat, code-drawn element after the UI kit, charm icons and fog passes. The owner's standing direction (2026-10-06): keep improving style and UI/UX, and treat flat Godot visuals as unfinished. PRD trace: §5 art direction, §2 *Jackpot payoff* (the first image promises the payoff), run-flow start screen.

**Pillars served:** *Jackpot payoff*: the first frame shows the game's core moment, a die locking in its amber ring with others still tumbling. *One thumb, one screen*: the start screen gets tighter and PLAY invites the tap.

## What Changes

- **Hero render:** `export_start_hero()` in `lockdown_art.py` renders `res://assets/ui/start_hero.png` (768×640, alpha) under the Smoke Room lamp. It uses the shipped production die mesh and Bone atlas:
  - the locked six-up die glowing in its amber and brass lock ring;
  - two dice caught mid-tumble above it;
  - amber sparks.

  No name or logo appears, per PRD Q4.
- **Start screen:**
  - the hero replaces the drawn mark and floats gently in an idle bob;
  - PLAY breathes with a slow scale pulse;
  - the how-to card fits its text, and line 2 is shortened so it no longer wraps.

## Capabilities

### Modified Capabilities
- `run-flow`: the start screen mark is the rendered hero, with an idle float and the PLAY pulse.
- `art-direction`: adds the production start hero asset.

## Impact

- `tools/art_direction/lockdown_art.py`, `assets/ui/start_hero.png` (LFS, lossless), `scripts/start_scene.gd`.
- No gameplay change.

## Non-goals

- Logo or wordmark (blocked on the name decision).
- An animated 3D scene on the start screen; a pre-rendered image keeps it cheap.
