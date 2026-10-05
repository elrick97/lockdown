class_name ScoringEngine
extends RefCounted
## Best-single-partition combo scoring (combo-scoring spec). Pure: no globals,
## no scene, no RNG — given a resolved throw it returns the same ScoreBreakdown
## every time. The tray cap (8 dice) keeps exhaustive partition search trivial,
## so the engine favors provable correctness over greedy shortcuts.

const _COMBO := ScoringConfig.ComboType


## Scores a resolved throw. window_duration feeds the Heat curve; steady
## selects the fixed Heat seam; inventory provides charm on_score hooks.
func score(result: ThrowResult, config: ScoringConfig,
		window_duration: float, steady: bool = false,
		inventory: CharmInventory = null) -> ScoreBreakdown:
	# Only locked, non-shattered dice score (combo-scoring + dice-materials spec).
	var locked: Array = []
	for idx in result.locked_order:
		if result.shattered.size() > idx and result.shattered[idx]:
			continue
		locked.append({"idx": int(idx), "face": int(result.faces[idx])})

	var counts := _counts_of(locked)
	var pips := 0
	for d in locked:
		var idx: int = d.idx
		var offset: int = result.pip_offsets[idx] if idx < result.pip_offsets.size() else 0
		var mult: int = result.pip_multipliers[idx] if idx < result.pip_multipliers.size() else 1
		pips += maxi(0, d.face + offset) * mult

	# Carved face effects: collect Gem bonus chips and Wild slots.
	var gem_chips := 0
	var wild_locked_slots: Array[int] = []
	for j in locked.size():
		var die_idx: int = locked[j].idx
		var carve: StringName = result.carve_types[die_idx] \
			if die_idx < result.carve_types.size() else &""
		if carve == &"gem":
			gem_chips += 20
		elif carve == &"wild":
			wild_locked_slots.append(j)

	var chosen: Array
	if wild_locked_slots.is_empty():
		var candidates := _candidates(counts)
		chosen = _search(candidates, 0, counts, [], pips, config)
	else:
		chosen = _best_wild_combos(locked, wild_locked_slots, pips, config)

	var heat := Heat.steady(config) if steady else Heat.from_remaining(
		result.window_remaining_s, config, window_duration)

	var bd := _build_breakdown(chosen, locked, pips, heat, config)
	bd.charm_chips += gem_chips

	# Fire charm on_score hooks in slot order before computing final total.
	if inventory != null:
		var ctx := CharmContext.from_result(result)
		for charm in inventory.iter_charms():
			charm.on_score(bd, ctx)

	bd.final_score = floori(
		float(bd.pips + bd.bonus_chips + bd.charm_chips)
		* (bd.combo_mult + bd.charm_mult) * bd.heat)
	return bd


# --- candidate generation ---------------------------------------------------

func _counts_of(locked: Array) -> Array:
	var counts := [0, 0, 0, 0, 0, 0, 0]  # index 1..6
	for d in locked:
		counts[d.face] += 1
	return counts


func _candidates(counts: Array) -> Array:
	var out: Array = []
	for v in range(1, 7):
		var c: int = counts[v]
		if c >= 2: out.append(_mk(_COMBO.PAIR, {v: 2}))
		if c >= 3: out.append(_mk(_COMBO.TRIPLE, {v: 3}))
		if c >= 4: out.append(_mk(_COMBO.QUAD, {v: 4}))
		if c >= 5: out.append(_mk(_COMBO.QUINT, {v: c}))  # all of them (5 or 6)
	for v1 in range(1, 7):
		for v2 in range(v1 + 1, 7):
			if counts[v1] >= 2 and counts[v2] >= 2:
				out.append(_mk(_COMBO.TWO_PAIR, {v1: 2, v2: 2}))
	for v1 in range(1, 7):
		for v2 in range(1, 7):
			if v1 != v2 and counts[v1] >= 3 and counts[v2] >= 2:
				out.append(_mk(_COMBO.FULL_HOUSE, {v1: 3, v2: 2}))
	for start in range(1, 4):  # 1-4, 2-5, 3-6
		if counts[start] >= 1 and counts[start + 1] >= 1 \
				and counts[start + 2] >= 1 and counts[start + 3] >= 1:
			out.append(_mk(_COMBO.SMALL_STRAIGHT,
				{start: 1, start + 1: 1, start + 2: 1, start + 3: 1}))
	var all_six := true
	for v in range(1, 7):
		if counts[v] < 1:
			all_six = false
	if all_six:
		out.append(_mk(_COMBO.LARGE_STRAIGHT, {1: 1, 2: 1, 3: 1, 4: 1, 5: 1, 6: 1}))
	return out


func _mk(type: int, consumed: Dictionary) -> Dictionary:
	var consume := [0, 0, 0, 0, 0, 0, 0]
	for face in consumed:
		consume[face] = consumed[face]
	return {"type": type, "consume": consume}


# --- best-partition search --------------------------------------------------

func _search(cands: Array, start: int, remaining: Array, chosen: Array,
		pips: int, config: ScoringConfig) -> Array:
	var best := chosen
	var best_eval := _eval(chosen, pips, config)
	# start = i (not i+1) so the same instance can recur — two pairs of one value.
	for i in range(start, cands.size()):
		var c: Dictionary = cands[i]
		if not _fits(c.consume, remaining):
			continue
		var next_remaining := remaining.duplicate()
		for v in range(1, 7):
			next_remaining[v] -= c.consume[v]
		var next_chosen := chosen.duplicate()
		next_chosen.append(c)
		var candidate_best := _search(cands, i, next_remaining, next_chosen, pips, config)
		var candidate_eval := _eval(candidate_best, pips, config)
		if _better(candidate_eval, best_eval):
			best = candidate_best
			best_eval = candidate_eval
	return best


func _fits(consume: Array, remaining: Array) -> bool:
	for v in range(1, 7):
		if consume[v] > remaining[v]:
			return false
	return true


func _eval(chosen: Array, pips: int, config: ScoringConfig) -> Dictionary:
	var chips := 0
	var mult := 0
	var top_rank := -1
	for c in chosen:
		chips += config.get_chips(c.type)
		mult += config.get_mult(c.type)
		top_rank = maxi(top_rank, c.type)
	var combo_mult: int = maxi(config.base_mult, mult)
	return {
		"chips": chips,
		"combo_mult": combo_mult,
		"key": float(pips + chips) * combo_mult,
		"count": chosen.size(),
		"top_rank": top_rank,
	}


## Strict "a beats b" with the spec's deterministic tie-break: higher score,
## then fewer combos, then higher-ranked top combo.
func _better(a: Dictionary, b: Dictionary) -> bool:
	if absf(a.key - b.key) > 0.000001:
		return a.key > b.key
	if a.count != b.count:
		return a.count < b.count
	return a.top_rank > b.top_rank


# --- breakdown assembly -----------------------------------------------------

func _build_breakdown(chosen: Array, locked: Array, pips: int,
		heat: float, config: ScoringConfig) -> ScoreBreakdown:
	var used: Array[bool] = []
	used.resize(locked.size())
	used.fill(false)

	var bd := ScoreBreakdown.new()
	bd.pips = pips
	bd.heat = heat

	var total_mult := 0
	for c in chosen:
		var dice_indices: Array[int] = []
		var faces: Array[int] = []
		for v in range(1, 7):
			var need: int = c.consume[v]
			while need > 0:
				for j in locked.size():
					if not used[j] and locked[j].face == v:
						used[j] = true
						dice_indices.append(locked[j].idx)
						faces.append(v)
						need -= 1
						break
		bd.combos.append({
			"name": config.get_combo_name(c.type),
			"type": c.type,
			"dice_indices": dice_indices,
			"faces": faces,
			"chips": config.get_chips(c.type),
			"mult": config.get_mult(c.type),
		})
		bd.bonus_chips += config.get_chips(c.type)
		total_mult += config.get_mult(c.type)

	for j in locked.size():
		if not used[j]:
			bd.loose_indices.append(locked[j].idx)

	bd.combo_mult = maxi(config.base_mult, total_mult)
	# final_score is computed in score() after charm on_score hooks fire.
	return bd


# --- Wild carving: try every face substitution, keep the best combo set ------

## Tries all 6^N substitutions for N wild slots and returns the chosen combo
## array that yields the highest scored combo value. N ≤ 2 in M1 (max 36 calls).
func _best_wild_combos(locked: Array, wild_locked_slots: Array[int],
		pips: int, config: ScoringConfig) -> Array:
	# Build the combination list: each entry is an Array[int] of face values
	# to substitute for each wild slot (in wild_locked_slots order).
	var combos: Array = [[]]
	for _i in wild_locked_slots.size():
		var expanded: Array = []
		for combo in combos:
			for v in range(1, 7):
				var nc: Array = combo.duplicate()
				nc.append(v)
				expanded.append(nc)
		combos = expanded

	var best: Array = []
	var best_eval := _eval([], pips, config)

	for face_vals in combos:
		var mod_locked := locked.duplicate()
		for s in wild_locked_slots.size():
			var j: int = wild_locked_slots[s]
			mod_locked[j] = {"idx": locked[j].idx, "face": face_vals[s]}
		var mod_counts := _counts_of(mod_locked)
		var mod_cands := _candidates(mod_counts)
		var mod_chosen := _search(mod_cands, 0, mod_counts, [], pips, config)
		var mod_eval := _eval(mod_chosen, pips, config)
		if _better(mod_eval, best_eval):
			best = mod_chosen
			best_eval = mod_eval

	return best
