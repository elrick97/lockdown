## Why

Every screen still uses Godot's default controls: flat gray buttons, plain labels, a full-width orange bar for the timer. The art direction (Smoke Room, `art-direction` spec) defines the UI language: dark panels with thin brass lines, amber as the only saturated accent, an oxblood THROW button. It also notes that against B's dark surround, the HUD and charm row must carry their own contrast. Two readability gaps hurt a public MVP. Shop offers show only a name and a price, never what the item does, and a player's owned charms and trinkets aren't visible during the run. This is TASKS.md M1 "UI layout pass: thumb-zone audit" (now local, owner rule) plus the UI half of the art pass. PRD trace: §5 layout, §2 *Readable depth* and *One thumb, one screen*.

**Pillars served:** *Readable depth*: every charm, die and trinket says what it does where you choose it, and your build is always on screen. *One thumb, one screen*: every interactive element sits in the bottom thumb zone at ≥ 48 dp.

## What Changes

- **Smoke Room theme** (`resources/ui/smoke_room_theme.tres`, built from the spec palette): panels `#0E0807` at 90% with 2 px brass `#CC994C` borders; amber `#FF9E29` for timer, accents and the score value; THROW in oxblood with a brass border; disabled states readable. Applied in code at scene setup, following the Android anchor gotcha (layout stays in code).
- **Throw screen layout to the frame's bands:**
  - HUD panel on top (ante/round, score, target);
  - window pips plus an amber draining timer under it;
  - tray in the middle;
  - an owned-charm row (5 slots, name plus one-line effect on tap) and trinket buttons above THROW;
  - SKIP in its own row.

  All buttons sit in the bottom 40% and are ≥ 48 dp (126 px).
- **Shop cards:** each offer is a panel with name, the full effect description, cost and BUY. Owned charms are listed at the top, so slot limits are visible. Gold sits in the HUD style.
- **Score readout restyled** (cascade unchanged: same timings and spec).
- **Font: decision for you** (below). Until then the engine's built-in font is styled by the theme.

## Decision for you: font

The style frames used no text. Options:
1. **Keep Godot's built-in font** (ships with the engine; no new license), styled by size and color. Zero risk; looks generic.
2. **Add one open-license display font for headings** (e.g. a condensed sans like *Oswald* or *Bebas Neue*, both SIL Open Font License 1.1), keeping the built-in font for body text. OFL allows bundling in a commercial game with the license file shipped alongside. Per CLAUDE.md I won't add any font until you approve a specific one.

Recommendation: 1 now, then 2 when the name decision (PRD Q4) sets the brand voice.

## Capabilities

### New Capabilities
- `ui-theme`: Smoke Room theme tokens, button/panel states, the throw-screen bands, thumb-zone and tap-size rules, shop card content, the owned-build display.

### Modified Capabilities
- `shop-scene`: offers show their effect description; owned charms are listed.
- `throw-loop`: trinket buttons move into the bottom band (behavior unchanged).

## Impact

- New theme resource + a small `UiStyle` helper; `throw_scene.gd`, `shop_scene.gd` layout and styling code; charm/trinket/material descriptions already exist in their `.tres`.
- Tests: every interactive control's rect ≥ 126 px and inside the bottom 40% (except HUD readouts); shop cards contain descriptions; owned-charm row reflects the inventory. Desktop playthrough screenshots of every screen.

## Non-goals

- New fonts without approval; logo or name (PRD Q4).
- Charm icons (separate change; slots show name + effect until then).
- Table, felt and overlay (`add-smoke-room-table`).
- Settings, accessibility palettes (M2).
