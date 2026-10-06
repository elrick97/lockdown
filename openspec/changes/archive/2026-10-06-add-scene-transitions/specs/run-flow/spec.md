## ADDED Requirements

### Requirement: Screen transitions
Every screen change SHALL go through the `SceneFader` autoload, and SHALL NOT be a hard cut. This covers start → throw, throw → shop, shop → throw, NEW RUN and MENU.
1. A full-screen smoke wipe covers the screen over `TRANSITION_S` (current 0.22 s).
2. The scene swaps under cover. The new screen draws for two frames.
3. The wipe reveals it over `TRANSITION_S`.

Taps are blocked while the wipe is up. With reduced motion, the wipe is a plain fade over `PLAIN_S` (0.15 s). Tools and tests can set `SceneFader.instant` for immediate swaps.

#### Scenario: PLAY
- **WHEN** the player presses PLAY
- **THEN** smoke covers the start screen, the throw screen is revealed, and taps work again once revealed
