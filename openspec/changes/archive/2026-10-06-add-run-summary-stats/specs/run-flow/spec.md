## ADDED Requirements

### Requirement: End-of-run stats and copyable seed
The end-of-run panel SHALL say how close the run came and what went well:
- **Result line:** under the final total, "MISSED BY <n>" (muted red) on a loss, or "BEAT BY <n>" (amber) on a win.
- **Summary:**
  - "Ante <a> / <total> · Best throw <n>";
  - "Best combo: <name>" (or "—");
  - "Rounds cleared <n> · Gold earned <g>".

  `RunCoordinator` records these per run as presentation data (`best_combo_type`, `rounds_cleared`, `gold_earned`), reset with the run; scoring never reads them.
- **Seed:** "Seed <n> · tap to copy". Tapping it copies the seed to the clipboard and floats "Copied".
- **Build:** with no charms, "No charms this run" replaces the empty sockets.
- **Behind the panel:** the status line is cleared and the ante intro card is closed.

#### Scenario: Close loss
- **WHEN** a run ends with 57 of 150
- **THEN** the panel reads "MISSED BY 93" under the total

#### Scenario: Seed copy
- **WHEN** the player taps the seed
- **THEN** the seed is on the clipboard and "Copied" floats up
