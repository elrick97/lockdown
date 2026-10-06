class_name ScoreBreakdown
extends RefCounted
## The full result of scoring a throw (combo-scoring spec). Carries the chosen
## partition itself — not just the total — so the M1 juice cascade can render
## from the same payload without touching the engine.

## Each entry: { name: String, type: int, dice_indices: Array[int],
##              faces: Array[int], chips: int, mult: int }
var combos: Array = []
var loose_indices: Array[int] = []
var pips: int = 0
var bonus_chips: int = 0
var combo_mult: int = 0
## Written by charm on_score hooks before final_score is computed.
var charm_chips: int = 0
var charm_mult: float = 0.0
## One entry per charm whose on_score changed the breakdown, in slot order:
## { slot: int, chips: int, mult: float } (deltas). Presentation only (trigger pulse).
var charm_triggers: Array = []
var heat: float = 1.0
## Presentation detail for the score cascade (score-cascade spec); never read by scoring.
## Each scoring die's pips in index order: { idx: int, pips: int }. Sums to `pips`.
var die_pips: Array = []
## Gem carve chips, already included in charm_chips.
var gem_chips: int = 0
var final_score: int = 0


func describe() -> String:
	var parts: Array[String] = []
	for c in combos:
		parts.append("%s %s" % [c.name, str(c.faces)])
	var combo_text := "—" if parts.is_empty() else ", ".join(parts)
	return "%s\n(%d + %d + %d) x (%d + %.1f) x %.2f = %d" % [
		combo_text, pips, bonus_chips, charm_chips, combo_mult, charm_mult, heat, final_score
	]
