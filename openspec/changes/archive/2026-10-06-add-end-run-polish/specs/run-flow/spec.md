## MODIFIED Requirements

### Requirement: End-of-run panel
When the run is won or lost, the throw screen SHALL show an end-of-run panel over a dimmer that covers everything on the throw screen; only the focus cover draws above it. THROW SHALL be hidden and disabled while the panel shows. The panel shows:
- **Result:** "RUN WON" (amber) or "GAME OVER" (cream), as a tilted stamp that slams in. A win shakes the screen at tier 4 and bursts sparks at tier 5; a loss shakes at tier 2 with no sparks. Tier values are from `FeedbackConfig`.
- **Final round total:** the headline. It counts up from 0 using the cascade's score-scaled tick and lands with a punch, with a caption giving the target.
- **Summary:** the ante reached out of the total, the best single-throw score, and the run seed.
- **Build:** the run's charm medallions under a "YOUR BUILD" caption.
- **Buttons:** NEW RUN (primary) and MENU, in the bottom thumb zone.

NEW RUN SHALL start a fresh run and reload the throw screen; MENU SHALL return to the start screen.

#### Scenario: Game over
- **WHEN** the final throw of a round leaves the total below target
- **THEN** the panel stamps GAME OVER, counts the final total up from 0 to the round total, lists the ante reached and best throw, and NEW RUN and MENU are enabled

#### Scenario: Run won
- **WHEN** the final ante's target is met
- **THEN** the panel stamps RUN WON with a shake and spark burst, and shows the same summary

#### Scenario: Nothing bright behind the panel
- **WHEN** the panel is shown
- **THEN** the tray, HUD, charm row and THROW are all drawn below the dimmer, and THROW is hidden
