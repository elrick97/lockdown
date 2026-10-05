class_name CharmStraightEdge
extends CharmEffect

func on_score(breakdown: ScoreBreakdown, ctx: CharmContext) -> void:
	for combo in breakdown.combos:
		if combo.name == "Small Straight" or combo.name == "Large Straight":
			breakdown.charm_mult += 3.0
			return
