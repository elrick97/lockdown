## MODIFIED Requirements

### Requirement: Die states read in the Smoke Room language
Die states SHALL read by shape and position, not colour alone.
- **Locked die:** it rises by `LOCK_LIFT` (current 0.12 world units) into a brass lock socket on the felt (`lock_socket.png`, `SOCKET_SIZE` 1.6 units), and shows a brass padlock badge at its front-right top corner (`padlock.png`, a billboard drawn over the die). It keeps its material colour.
- **Unlocked dice:** while any die is locked, unlocked live dice dim to `UNLOCKED_DIM` (0.88).
- **Dead slot (shattered Glass):** drawn at `DEAD_TINT` (0.38) with a crack overlay (`crack.png`, triplanar pass). It is static and never shows a socket. The throw screen floats "SHATTERED" over a die once, when it newly shatters.
- **Cascade flash:** the score cascade's per-die flash stays an amber pulse.
- **Shadows:** every die has a soft contact (blob) shadow. These states use unshaded or textured quads and sprites, not real-time shadows.

Hit rects and timing are unchanged.

#### Scenario: Locked die stays readable
- **WHEN** a Glass die is locked
- **THEN** it rises into its socket with a padlock badge and keeps its Glass look, and the unlocked dice dim

#### Scenario: Dead slot
- **WHEN** a Glass die shatters
- **THEN** it is drawn dark with a crack overlay, does not tumble, shows no socket, and "SHATTERED" floats once
