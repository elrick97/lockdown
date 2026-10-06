# ui-theme Specification

## Purpose
The shared Smoke Room UI theme and screen layouts: palette tokens, thumb-zone and tap-size rules, throw-screen bands, owned-build display and shop cards.
## Requirements
### Requirement: Smoke Room theme on every screen
Every screen (start, throw, shop, end-of-run panel) SHALL use one shared theme built from the art-direction palette. Panels are dark (`#0E0807` at 90%) with 2 px brass `#CC994C` borders. Text is cream `#F2E6D0`. Amber `#FF9E29` is the only saturated accent: timer fill, score readout, pressed state. THROW and PLAY use the oxblood variant with a brass border. Buttons are opaque, and disabled buttons stay legible (dimmed text, muted border). Font: the engine's built-in font (owner decision, 2026-10-06).

#### Scenario: Theme applied
- **WHEN** any screen is shown
- **THEN** its root control uses the shared theme, and no control falls back to the engine's default gray button style

#### Scenario: Disabled is readable
- **WHEN** THROW is disabled during a throw
- **THEN** its label is still legible against its background

### Requirement: Thumb-zone layout and tap size
On the throw screen and the end-of-run panel, every interactive control (THROW, SKIP, trinket buttons, charm slots, NEW RUN, MENU) SHALL sit in the bottom 40% of the screen (y ≥ 1440 at base resolution) and be at least 126 px (48 dp) tall and wide. On the shop, BUY, RE-ROLL and CONTINUE SHALL be at least 126 px tall and sit in the bottom 55% (y ≥ 1080). The start screen's PLAY follows the throw-screen rule.

#### Scenario: Throw screen controls
- **WHEN** the throw screen is laid out at 1080×2400 with two trinkets and five charm slots
- **THEN** every listed control's rect is ≥ 126 × 126 px and starts at y ≥ 1440

#### Scenario: Shop controls
- **WHEN** the shop shows three offers
- **THEN** each BUY button is ≥ 126 px tall and starts at y ≥ 1080

### Requirement: Throw screen bands
The throw screen SHALL be laid out top to bottom as: a HUD panel (ante and round name, throw count, round total vs target in amber), status and score readout, an amber timer bar on a dark track, the tray (27%–66% of height), the owned-charm row (five slots), a row shared by trinket buttons (during lock windows) and SKIP (before the first throw on a Risk ante), and THROW.

#### Scenario: Owned build on screen
- **GIVEN** the player owns Quick Draw and Loaded
- **WHEN** the throw screen opens
- **THEN** the charm row shows both names in the first two slots and three empty slots, and tapping a charm shows its effect description in the status line

### Requirement: Shop cards say what items do
Each shop offer SHALL be a card showing the item's name, its full effect description, its cost and BUY. The shop SHALL show the player's gold in an amber readout and list the charms already owned with the slot count (e.g. "Charms 2 / 5").

#### Scenario: Description shown
- **WHEN** the shop offers Hair Trigger
- **THEN** its card shows "Each die locked in Window 1 adds +5 Chips."

#### Scenario: Owned charms listed
- **GIVEN** the player owns Quick Draw
- **WHEN** the shop opens
- **THEN** it reads "Charms 1 / 5: Quick Draw"

