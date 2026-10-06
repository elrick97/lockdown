## Why

UI/UX audit findings B1, B2, C4 and F3:
- **Boss rule never stated:** the boss round silently halves the lock windows; the screen only says "BOSS ROUND".
- **Risk skip shows one side:** "SKIP RISK (+3g)" shows the skip reward but not what playing would pay.
- **Ambiguous labels:** "Throw 0 / 3" and "Total: 0 / 150" don't say "next throw" or "target".
- **Shop look-ahead:** the shop gives no warning of what's next.

Balatro's blind-select screen states the target, the reward and the boss rule in plain words before you play. Telegraphing modifiers is a core readability rule (Slay the Spire intents). PRD trace: §2 *Readable depth*; §4.4 ante arc (open, risk, boss).

## What Changes

- **Ante intro card:** shown on entering each ante's throw screen, before the first throw, reusing the inspect-card frame. Every ante shows:
  - the ante name ("ANTE 2 · RISK ROUND");
  - the target;
  - the reward: "Win: 4g + 1g per spare throw".

  Ante-specific content:
  - **Boss:** the rule in plain words, "Lock windows halved (1.25 s)", with a stopwatch glyph.
  - **Risk:** the trade-off, "Play for 4g + 1g per spare throw — or SKIP for 3g". The SKIP button moves onto this card.

  PLAY (the ThrowButton style) dismisses the card. It is never shown mid-round.
- **Boss chip:** during the boss ante, a small "½ WINDOWS" chip sits in the HUD. Tapping it re-opens the rule.
- **HUD label copy:**
  - "Throw 1 of 3" means the next throw.
  - "TARGET 150" plus "TOTAL 0".
- **Shop look-ahead:** a "NEXT: ANTE 3 · BOSS · target 700 · ½ windows" strip fills the band between YOUR DICE and the offers.

## Capabilities

### Modified Capabilities
- `throw-loop`: adds the ante intro card and the boss chip; HUD label copy.
- `ante-arc`: the risk and boss rules are presented before play.
- `shop-scene`: adds the next-ante strip.

## Impact

- `throw_scene.gd`, `shop_scene.gd`, `inspect_card.gd` (frame reuse), plus one Blender glyph (stopwatch, reusing the Freeze Timer emblem style).
- No rule or tunable change: the values are read from `AnteConfig` and `ShopConfig`.
