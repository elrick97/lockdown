class_name CharmPrecision
extends CharmEffect

func on_score(breakdown: ScoreBreakdown, ctx: CharmContext) -> void:
	if ctx.locked_faces.is_empty():
		return
	var face0: int = ctx.locked_faces[0]
	for face in ctx.locked_faces:
		if face != face0:
			return
	breakdown.charm_mult += 2.0
