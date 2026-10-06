## Why

Owner feedback (2026-10-06): "I don't like the outer white flickering, I'd rather have a nice foggy smoke." The overlay's film grain adds per-pixel white noise that changes 24 times a second. On the dark walnut edges it reads as white flicker, not atmosphere. The direction is called *Smoke Room*, and the room should look smoky. PRD trace: §5 art direction (Smoke Room mood), §2 *Flow under pressure* (no distracting flicker at the edge of vision while timing locks).

**Pillars served:** *Flow under pressure*: calm, slow motion at the periphery instead of flicker. *Readable depth*: the fog stays off the play area and HUD, so readability is unchanged.

## What Changes

- **Film grain removed:** the overlay's grain pass is gone.
- **Drifting fog:** slow, domain-warped fog replaces it, in warm grey smoke lit by the lamp. It hangs in the side margins and corners, rises from the bottom, and stays light over the HUD. Only a faint haze covers the play area.
- **Cheap to render:** the overlay stays one full-screen canvas pass, sampling one small seamless fractal-noise texture four times per pixel. That is GL Compatibility and mobile safe, and well inside `overlay_passes_max`.
- **Vignette unchanged.**
- **New tunables:** `fog_edge`, `fog_center`, `fog_drift` and `fog_color` replace `grain`.

## Capabilities

### Modified Capabilities
- `art-direction`: the overlay tunables (grain becomes fog) and the production overlay requirement.

## Impact

- `resources/ui/smoke_overlay.gdshader`, `scripts/smoke_overlay.gd` (generated noise texture, fixed seed, shared across screens).
- No gameplay, input or layout change; the overlay still ignores input.

## Non-goals

- Particle smoke or smoke reacting to gameplay; a later juice pass could add that.
- Bloom (still optional, not enabled).
