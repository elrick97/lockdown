class_name CharmLoaded
extends CharmEffect

func on_score(breakdown: ScoreBreakdown, ctx: CharmContext) -> void:
	for face in ctx.locked_faces:
		if face == 6:
			breakdown.charm_chips += 6
