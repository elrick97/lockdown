class_name CharmIceCold
extends CharmEffect

func on_score(breakdown: ScoreBreakdown, ctx: CharmContext) -> void:
	for w in ctx.locked_windows:
		if w == 1:
			return
	breakdown.charm_mult += 3.0
