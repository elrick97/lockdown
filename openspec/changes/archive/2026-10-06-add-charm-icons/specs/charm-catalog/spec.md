## ADDED Requirements

### Requirement: Every M1 charm has its medallion
Each of the 12 charm resources SHALL point its `icon` at `res://assets/charms/<id>.png`, a 256×256 medallion. The enamel colour shows the archetype:
- **Speed:** amber.
- **Slow:** deep blue.
- **Value:** green.
- **Combo:** oxblood.
- **Inversion:** violet.

The emblem hints at the rule, for example a bolt for Hair Trigger, an hourglass for Patient Zero, a six-face for Loaded and a snake for Snake Charmer.

#### Scenario: All icons present
- **WHEN** each `.tres` in `res://resources/charms/` is loaded
- **THEN** its `icon` is a 256×256 texture
