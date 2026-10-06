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

### Requirement: UI chrome is the rendered Smoke Room kit
Buttons, panels, readout plaques, charm sockets and the timer SHALL be drawn with the rendered UI kit (`res://assets/ui/`) as 9-patch textures, not flat colour boxes:
- **Primary buttons** (THROW, PLAY, CONTINUE): oxblood lacquer in a brass bezel.
- **Secondary buttons:** walnut in a brass bezel.
- **Panels:** stitched leather in a riveted brass frame.
- **Plaques** for readouts such as the round total and gold.
- **Sockets** for charm slots.
- **Timer:** a brass tube with an amber fill.

Each button has distinct normal, pressed and disabled art; hover brightens the normal art. Text on buttons has a dark outline, and text on labels a dark drop shadow, so it reads on lacquer, wood and felt. The `ui-theme` size and thumb-zone rules are unchanged.

#### Scenario: No flat boxes left
- **WHEN** any screen is shown
- **THEN** every button, panel, plaque, slot and the timer uses a texture from the UI kit

#### Scenario: Pressed and disabled read differently
- **WHEN** THROW is pressed, and later disabled during a throw
- **THEN** the pressed state shows the sunk, darker lacquer and the disabled state the dull, unlit lacquer

### Requirement: Charms show as medallions and pulse when they fire
Wherever a charm appears, it SHALL show its medallion:
- **Throw screen charm slots:** the icon over the socket. Tapping a slot shows the name and rule in the status line.
- **Shop offer cards:** the icon left of the text, for charms only.
- **Shop owned row:** the build as medallions, with empty slots as dim sockets.
- **End-of-run panel:** the run's build, shown the same way as the shop owned row.

During the score cascade, after the combo label pops, each slot in `charm_triggers` SHALL pulse in slot order, `charm_pulse_gap_s` (current 0.18 s) apart. A pulse scales the slot to about 1.28×, brightens it, then settles elastically.

#### Scenario: Only firing charms pulse
- **WHEN** a throw is scored and only some owned charms changed the score
- **THEN** exactly those slots pulse

#### Scenario: Build visible in the shop
- **WHEN** the shop opens with 3 charms owned
- **THEN** the owned row shows 3 medallions and 2 empty sockets

### Requirement: Shared inspect card
Every item the player can own or buy SHALL be inspectable through one shared inspect card (`InspectCard`):
- a leather panel, 980 px wide, over a 45% dark scrim;
- the item's icon at 150 px;
- its name;
- a type tag: "CHARM · always on", "<MATERIAL> DIE · joins your bag", "CARVED DIE · joins your bag" or "TRINKET · one use, during a lock window";
- the full rule text, wrapped inside the card;
- the cost, in the shop.

It opens on a tap of:
- a charm slot on the throw screen (card just above the charm row);
- a medallion in the shop's YOUR BUILD row, or an offer's icon (card in the band above the offers);
- a medallion in the end-of-run build row (card above the build, drawn over the end panel).

Any tap anywhere dismisses it. The card never takes input, so the dismissing tap still reaches what is underneath. During a lock window a die tap still locks, and nothing pauses. The status-line charm text is removed.

#### Scenario: Long rule fits
- **WHEN** the player taps a charm whose rule is longer than one line
- **THEN** the card shows the whole rule wrapped inside its 980 px width

#### Scenario: Locking with the card open
- **GIVEN** the inspect card is open during a lock window
- **WHEN** the player taps a die
- **THEN** the card closes, the die locks, and the window timer never paused

#### Scenario: Shop offer
- **WHEN** the player taps an offer's icon in the shop
- **THEN** the card shows that item's name, type tag, rule and cost

### Requirement: Settings
Player settings SHALL persist in `user://settings.cfg` (autoload `Settings`). They change presentation only:
- **Screen shake:** 100% / 50% / 0%. Scales every screen shake and the tray nudge.
- **Score speed:** 1× / 2× / Instant. Scales the cascade timeline; Instant skips the cascade to its final state.
- **Reduced motion:** turns shake off, makes stamps fade in place instead of slamming, and stops the start screen's idle float and PLAY pulse.
- **Haptics:** on / off.

Settings open from the pause menu, and from a Blender gear chip on the start screen (bottom-left, settings-only mode with DONE).

#### Scenario: Shake off
- **WHEN** screen shake is 0% or reduced motion is on
- **THEN** combos and locks move neither the screen nor the tray

#### Scenario: Instant score
- **WHEN** score speed is Instant and a throw resolves
- **THEN** the cascade lands on its final values immediately and THROW is available

### Requirement: In-game references
The pause menu SHALL include:
- **How to play:** the four start-screen lines plus "Locks are final".
- **Combos:** all eight combos, each with how it matches and its base chips × mult, read from `ScoringConfig`, plus a one-line reminder of Chips × Mult × Heat.

#### Scenario: Combos list
- **WHEN** the player opens Combos
- **THEN** "Pair — 2 of a kind · 10 × 1" through "Quint — 5+ of a kind · 100 × 8" are listed

### Requirement: Readable captions and progress copy
Text SHALL stay readable on a phone:
- Captions (plaque captions, YOUR BUILD / YOUR DICE, inspect tags) SHALL be at least 30 px, about 11 pt on a phone.
- TAP TO SKIP is 34 px.
- The HEAT value is 52 px.
- `UiStyle.MUTED` is #A8977C.

After each throw, the status band SHALL report progress:
- "<scored> scored · <to go> to go · <n> throws left";
- on the last throw, "LAST THROW · NEED <to go>";
- once the target is met, "Target hit!".

The Combos page SHALL define pips and CHIPS ("Pips are a die's face points. CHIPS = pips + combo and charm chips.").

#### Scenario: Last throw
- **WHEN** a throw leaves one throw and 90 points to go
- **THEN** the status reads "LAST THROW · NEED 90"

### Requirement: First-time tips
The game SHALL show a one-line coach mark (a plaque bubble with a brass pointer) once per player, the first time each moment happens:
- first lock window: "Tap a die to lock it. Locks are final.";
- first lock: "Locked! The rest re-roll when the timer runs out.";
- first combo: "<COMBO> = <c> chips × <m> mult. Bigger combos score more.";
- first time HEAT drops below max: "Heat: lock sooner for a bigger multiplier.";
- first shop: "Charms change how you score. Tap any icon to read it.";
- first boss window: "Boss: lock windows are half as long."

Only one tip shows at a time.

Tips never pause the game or take input. Any tap dismisses the tip and still reaches the die or button underneath. Tips hide after 6 s.

Seen tips persist with the settings. Settings offers "Tips: On / Off" and "Show tips again". Headless tests and the playthrough harness never read or write the player's settings file.

#### Scenario: Once only
- **WHEN** the first lock window opens, and later another one
- **THEN** the lock tip shows the first time only

#### Scenario: Tip never blocks a lock
- **GIVEN** the lock tip is showing
- **WHEN** the player taps a die
- **THEN** the die locks and the tip closes

