## MODIFIED Requirements

### Requirement: Tap-to-lock with forgiveness
During a lock window, a tap SHALL resolve to the nearest die, in any state, whose bounds are within `tap_forgiveness_radius_px` (current 96 px) of the tap point:
- **Unlocked die:** it locks.
- **Locked or shattered die:** nothing locks, and the die plays a short "denied" wiggle that returns it exactly to its resting position.

Taps outside the radius do nothing. Locks are irreversible for the remainder of the throw, so a tap aimed at a locked die SHALL never lock a different die.

#### Scenario: Direct tap
- **WHEN** the player taps on an unlocked die during a window
- **THEN** that die locks immediately and is excluded from future re-rolls

#### Scenario: Near miss snaps
- **WHEN** the player taps within `tap_forgiveness_radius_px` of an unlocked die, not on it, and no other die is nearer
- **THEN** that die locks

#### Scenario: Tap cannot unlock
- **WHEN** the player taps a locked die
- **THEN** it stays locked, wiggles "denied", and no other die locks

#### Scenario: Gap next to a locked die
- **WHEN** the player taps in the gap between a locked die and an unlocked one, nearer the locked die
- **THEN** nothing locks
