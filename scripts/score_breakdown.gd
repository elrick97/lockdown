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
var charm_mult: int = 0
var heat: float = 1.0
var final_score: int = 0


func describe() -> String:
	var parts: Array[String] = []
	for c in combos:
		parts.append("%s %s" % [c.name, str(c.faces)])
	var combo_text := "—" if parts.is_empty() else ", ".join(parts)
	return "%s\n(%d + %d) x (%d + %d) x %.2f = %d" % [
		combo_text, pips, bonus_chips, combo_mult, charm_mult, heat, final_score
	]
