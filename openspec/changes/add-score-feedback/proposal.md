## Why

The owner's direction (2026-10-06): feedback from playing should be loud and easy to follow, "just like Balatro": combos shake the screen and you can see what's going on. Today a throw ends with dice flashing one by one, a combo label that pops, and a single number ticking up. The player can't see why that number: which dice scored, what the combo added, what Heat multiplied. Locks and charms barely react. Feedback is P0 in the PRD ("the feedback loop *is* the product"), and the current juice pass covered only lock haptics, one fixed shake and audio stubs. PRD trace: §5 juice, §3.3 scoring model, §2 *Jackpot payoff* and *Readable depth*.

**Pillars served:** *Jackpot payoff*: escalation you can see and feel, scaled to how big the hand is. *Readable depth*: the score formula plays out on screen, so the player learns Chips × Mult × Heat by watching it.

## What Changes

- **Chips × Mult readout, Balatro-style:** two plaques under the HUD, CHIPS (cream) and MULT (amber), with ×HEAT beside them. During the cascade they fill step by step:
  1. each scoring die adds its pips to CHIPS with a floating "+n" rising from the die;
  2. the combo stamps in and adds its chips and mult;
  3. each triggered charm pulses and adds its part;
  4. Heat multiplies;
  5. the product slams into the throw score, which then pours into the round total.
- **Combo stamp and shake scaled to the hand:** the combo name lands as a big stamped banner. Screen shake and a brass-spark burst scale with the combo tier: a pair is a nudge, a full house a jolt, quads and quints a heavy shake and a big burst. The tiers are named tunables.
- **Score pacing scales too:** bigger scores tick longer and faster, with a punch when they land (tunable curve).
- **Target progress:** a bar under the round total fills as score pours in. Hitting the target triggers a "TARGET HIT" flourish before the shop.
- **Lock feedback:** a locked die punches (scale pop), its ring snaps in, and a tiny shake plays. The timer bar pulses and shifts toward oxblood in its last 0.8 s (urgency).
- **Heat feedback during windows:** a live ×HEAT readout that drops as time drains, so the speed-versus-value dilemma is visible while you decide.
- Respects existing rules: the cascade stays skippable (headless), THROW re-enables only when it finishes, there's no audio (deferred), and scoring math is untouched (presentation only).

## Capabilities

### New Capabilities
- None.

### Modified Capabilities
- `score-cascade`: the step-by-step Chips × Mult × Heat sequence, floating numbers, combo stamp, tiered shake and burst, target bar, named timing tunables.
- `throw-loop`: lock feedback and timer urgency (presentation; timing unchanged).
- `heat`: a live Heat readout during windows (display of the existing formula; no formula change).

## Impact

- `scripts/score_cascade.gd` rebuilt as a step sequence; new small effect helpers (floating number, spark burst, stamp); `throw_scene.gd` plaques and the target bar; `viewport_3d_dice_tumbler.gd` die punch.
- Tests: the cascade steps sum to the breakdown exactly (what you see equals what you score); shake amplitude rises with tier; skip still jumps to the final state; THROW stays disabled until the end. Desktop playthrough screenshots mid-cascade.

## Non-goals

- Audio (owner deferred).
- Any scoring, Heat-formula or timing change.
- Charm icons (`add-charm-icons`; this change pulses whatever the slot shows).
