class_name CharmCollector
extends CharmEffect

func on_score(breakdown: ScoreBreakdown, ctx: CharmContext) -> void:
	var seen: Dictionary = {}
	for face in ctx.locked_faces:
		seen[face] = true
	breakdown.charm_mult += float(seen.size())
