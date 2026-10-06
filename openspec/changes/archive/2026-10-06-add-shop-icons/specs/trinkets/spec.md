## ADDED Requirements

### Requirement: Trinkets carry an icon
`Trinket` SHALL expose `@export var icon: Texture2D`. Each shipped trinket points at its chip in `res://assets/shop/`. The throw screen's trinket buttons SHALL show the icon left of the name, with its width capped at 92 px.

#### Scenario: Trinket button shows its chip
- **WHEN** the player owns Freeze Timer and a lock window opens
- **THEN** its button shows the stopwatch chip beside "Freeze Timer"
