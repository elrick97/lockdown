class_name CharmSnakeCharmer
extends CharmEffect

func on_score(breakdown: ScoreBreakdown, ctx: CharmContext) -> void:
	var ones := 0
	for face in ctx.locked_faces:
		if face == 1:
			ones += 1
	if ones != 2:
		return
	if breakdown.combos.is_empty() or breakdown.combos[0].name != "Pair":
		return
	breakdown.combo_mult = 4
	breakdown.bonus_chips = 0
