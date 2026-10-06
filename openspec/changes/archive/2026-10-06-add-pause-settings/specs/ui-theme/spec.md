## ADDED Requirements

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
