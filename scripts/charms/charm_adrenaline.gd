class_name CharmAdrenaline
extends CharmEffect

func on_score(breakdown: ScoreBreakdown, ctx: CharmContext) -> void:
	var count := 0
	for w in ctx.locked_windows:
		if w == 1:
			count += 1
	if count >= 3:
		breakdown.charm_mult += 1.0
