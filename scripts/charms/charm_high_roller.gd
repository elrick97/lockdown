class_name CharmHighRoller
extends CharmEffect

func on_score(breakdown: ScoreBreakdown, ctx: CharmContext) -> void:
	if breakdown.combos.is_empty():
		return
	var top: String = breakdown.combos[0].name
	if top == "Quad" or top == "Quint":
		breakdown.charm_chips += 60
