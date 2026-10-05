class_name CharmPatientZero
extends CharmEffect

func on_score(breakdown: ScoreBreakdown, ctx: CharmContext) -> void:
	for w in ctx.locked_windows:
		if w == 3:
			breakdown.charm_chips += 5
