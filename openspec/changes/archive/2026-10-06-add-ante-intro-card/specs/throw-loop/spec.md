## ADDED Requirements

### Requirement: Ante intro card
On entering an ante's throw screen before its first throw, the throw screen SHALL show an intro card over a dimmer. The card shows:
- the ante title ("ANTE n · <NAME> ROUND"), stamped in;
- "TARGET <n>";
- the reward: "Win: <base>g + <per>g per spare throw";
- the ante's rule in plain words:
  - Boss: "Boss rule: lock windows halved (<s> s)";
  - Risk: "Or skip this round for +<n>g", with the SKIP button on the card;
  - otherwise: "<n> throws to beat the target".

All text comes from `AnteBrief`, read from `AnteConfig`, `ShopConfig` and `ThrowConfig`. PLAY sits where THROW is, and pressing it (or THROW) dismisses the card. Tapping the HUD's ante label re-opens the card between throws, never while a throw or cascade is running. SKIP only shows before the first throw.

#### Scenario: Boss rule stated
- **WHEN** the player enters ante 3
- **THEN** the intro card reads "Boss rule: lock windows halved (1.25 s)" before any throw

#### Scenario: Risk trade-off
- **WHEN** the player enters the Risk ante
- **THEN** the card shows the win reward and "Or skip this round for +3g", with SKIP on the card

### Requirement: HUD labels name the next throw and the target
The HUD SHALL show the throw about to be made or in progress ("Throw 1 of 3" before the first throw). It SHALL show the round total as "Total <n> · Target <m>". On the boss ante, the ante label SHALL carry the rule chip "· ½ WINDOWS".

#### Scenario: Fresh round
- **WHEN** a round starts
- **THEN** the HUD reads "Throw 1 of 3" and "Total 0 · Target <target>"
