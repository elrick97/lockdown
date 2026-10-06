## Why

Charms show as text only: a name in a slot, or a name and effect on a shop card. Balatro-likes live on recognisable art. A player should spot their build at a glance and see a charm trigger without reading. TASKS.md M1 still has "Placeholder → first-pass dice/charm art" open with only the charm half left, and the style frames already proved the medallion icon (the Hair Trigger token). PRD trace: §4.1 charms, §5 art direction, §4.5 *Collect & unlock* (the collection journal will reuse these icons).

**Pillars served:** *Readable depth*: one icon per archetype-coloured medallion, readable at slot size. *Collect & unlock*: each charm becomes a collectible object.

## What Changes

- **`CharmEffect.icon: Texture2D`** (data, per CLAUDE.md "content is data"). Each of the 12 charm `.tres` files points at its icon, so adding a charm stays a resource plus an icon, with no code.
- **12 Blender-made medallions** (`res://assets/charms/<id>.png`, 256², alpha): the brass/enamel token from the art direction, with an emblem per charm that hints at its rule (bolt for Hair Trigger, hourglass for Patient Zero, a 6-face for Loaded, a snake for Snake Charmer, and so on). Enamel colour by archetype: amber for speed, deep blue for slow, green for value, oxblood for combo, violet for inversion.
- **Shown everywhere a charm appears:** the throw screen's charm slots (icon over the socket, name on tap), shop cards (icon left of the text) and the end-of-run panel (the run's build).
- **Trigger pulse:** when a charm's hook changes the score during the cascade, its slot icon pulses. This is the visible "this charm did something" feedback; the scoring-side signal comes from the existing hooks, with no engine change.

## Capabilities

### New Capabilities
- None.

### Modified Capabilities
- `charm-effect`: `CharmEffect` carries an `icon`.
- `charm-catalog`: each M1 charm has its icon.
- `ui-theme`: charm slots and shop cards show icons; triggered charms pulse.

## Impact

- `scripts/charm_effect.gd` (+ the `icon` export), 12 charm `.tres`; `tools/art_direction/lockdown_art.py` icon export; throw/shop/end-panel display; a small `charm_triggered` record from the score breakdown for the pulse.
- Tests: every catalog charm has a 256² icon; the slots show icons; the pulse fires for a charm that changed the score and not for one that didn't. Balance sim: not needed (no rule change).

## Non-goals

- Charm rules or costs (unchanged).
- Collection journal (M2).
- New charms (M2 waves).
