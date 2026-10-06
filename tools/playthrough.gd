extends SceneTree
## Local desktop playthrough (verification is local-only, CLAUDE.md). Runs the real
## ThrowScene/ShopScene windowed, sets up the state each scenario needs, drives
## the scenes with synthetic taps and button presses, and records evidence:
## screenshots + report under build/playthrough/ (gitignored).
##   godot_console --path . --rendering-driver opengl3 -s tools/playthrough.gd
## Exit code = number of failed checks.

const OUT_DIR := "res://build/playthrough/"
const THROW_SCENE := "res://scenes/throw/throw_scene.tscn"
const SHOP_SCENE := "res://scenes/shop/shop_scene.tscn"
const TIMEOUT_S := 10.0

# Autoloads are looked up at runtime: -s scripts compile before autoload names exist.
var _rc: Node
var _rng: Node
var _report: PackedStringArray = []
var _failures := 0
var _shot := 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	_rc = root.get_node("RunCoordinator")
	_rng = root.get_node("RngService")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	await _scenario_dice_materials()
	await _scenario_carving()
	await _scenario_trinkets()
	await _scenario_boss()
	await _scenario_risk_skip()
	await _scenario_juice()
	_report.append("\n%d check(s) failed" % _failures)
	var f := FileAccess.open(OUT_DIR + "report.md", FileAccess.WRITE)
	f.store_string("\n".join(_report) + "\n")
	f.close()
	# Free the last scene before quitting, so exit doesn't report its textures as leaked.
	if current_scene != null:
		current_scene.queue_free()
	await process_frame
	await process_frame
	quit(_failures)


# --------------------------------------------------------------- scenarios
func _scenario_dice_materials() -> void:
	_section("add-dice-materials")
	# Iron: -1 pip per die, slower tumble (factor 1.4).
	var scene := await _load_run(1, func(bag: DiceBag) -> void: bag.add(&"iron", 6))
	_press(scene._throw_button)
	var anim_s: float = scene._tumble_duration_s()
	var base_s: float = scene._config.tumble_duration_s
	_check(absf(anim_s - base_s * 1.4) < 0.01, "Iron tumble animation is 1.4x base (%.2fs)" % anim_s)
	# Frame-independent: 1.8 s in, the base tumble (1.5 s) would have opened the window;
	# Iron's 2.1 s must not have yet.
	var t0 := Time.get_ticks_msec()
	await _wait(func() -> bool: return Time.get_ticks_msec() - t0 >= 1800)
	_check(scene._controller.state == ThrowController.State.TUMBLE,
		"Iron: still tumbling 1.8 s in (window opens after the slower 2.1 s tumble)")
	await _wait(func() -> bool: return scene._controller.state == ThrowController.State.LOCK_WINDOW)
	await _lock_all(scene)
	await _wait(func() -> bool: return scene._controller.state == ThrowController.State.RESOLVED)
	var r: ThrowResult = scene._controller.last_result
	var b: ScoreBreakdown = _score(scene, r)
	var raw_pips := 0
	for i in r.faces.size():
		if i in b.loose_indices or _in_combos(b, i):
			raw_pips += r.faces[i]
	_check(r.pip_offsets.all(func(o: int) -> bool: return o == -1), "Iron dice carry pip_offset -1")
	_check(b.pips < raw_pips, "Iron scores fewer pips than the faces show (%d < %d)" % [b.pips, raw_pips])
	await _screenshot("materials_iron_scored")
	# Glass: x2 pips when locked in W1; un-locked Glass shatters into dead slots.
	# One Bone die keeps the throw going into Window 2.
	var glass_bag := func(bag: DiceBag) -> void:
		bag.add(&"glass", 5)
		bag.add(&"standard", 1)
	scene = await _load_run(1, glass_bag)
	_press(scene._throw_button)
	await _wait(func() -> bool: return scene._controller.state == ThrowController.State.LOCK_WINDOW)
	var ctrl_g: ThrowController = scene._controller
	var glass_idx := _indices_of(ctrl_g, &"glass")
	var bone_i: int = _indices_of(ctrl_g, &"standard")[0]
	var kept: int = glass_idx[0]
	var dead_idx := glass_idx.slice(1)
	_tap_die(scene, kept)  # keep one Glass die, let the other four shatter
	await _wait(func() -> bool: return ctrl_g.state == ThrowController.State.REROLL)
	_check(not ctrl_g.is_shattered(kept) and dead_idx.all(func(i: int) -> bool: return ctrl_g.is_shattered(i)),
		"Glass: the 4 un-locked Glass dice shattered on re-roll, the locked one survived")
	var faces_at_shatter := ctrl_g.faces.duplicate()
	_check(dead_idx.all(func(i: int) -> bool: return scene._tumbler.dead[i] and scene._tumbler.is_static(i)),
		"Glass: shattered dice are drawn as static, dimmed dead slots (not re-tumbling)")
	await _screenshot("materials_glass_after_reroll")
	await _wait(func() -> bool: return ctrl_g.state == ThrowController.State.LOCK_WINDOW)
	_check(not ctrl_g.lock_die(dead_idx[0]), "Glass: a dead slot cannot be locked")
	_tap_die(scene, bone_i)  # the last live die
	_check(ctrl_g.state == ThrowController.State.RESOLVED,
		"Dead slots: locking the last live die resolves at once (no waiting out W2/W3)")
	r = ctrl_g.last_result
	_check(r.window_remaining_s[1] > 0.0 and is_equal_approx(r.window_remaining_s[2], 2.5),
		"Dead slots: the early lock is credited (window times %s)" % [r.window_remaining_s])
	_check(dead_idx.all(func(i: int) -> bool: return r.faces[i] == faces_at_shatter[i]),
		"Glass: dead slots keep their last face")
	_check(r.pip_multipliers[kept] == 2, "Glass die carries pip_multiplier 2")
	b = _score(scene, r)
	_check(b.pips == r.faces[kept] * 2 + r.faces[bone_i],
		"Glass: the locked Glass die scores x2 pips, dead slots score nothing (%d)" % b.pips)
	await _screenshot("materials_glass_scored")
	# Nothing left to lock: Bone locked in W1, the five Glass dice shatter at expiry.
	scene = await _load_run(1, glass_bag)
	_press(scene._throw_button)
	await _wait(func() -> bool: return scene._controller.state == ThrowController.State.LOCK_WINDOW)
	var ctrl_n: ThrowController = scene._controller
	var rerolls: Array[int] = []
	ctrl_n.reroll_started.connect(func(idx: Array[int]) -> void: rerolls.append(idx.size()))
	_tap_die(scene, _indices_of(ctrl_n, &"standard")[0])
	await _wait(func() -> bool: return ctrl_n.state == ThrowController.State.RESOLVED)
	r = ctrl_n.last_result
	_check(rerolls.is_empty(), "Nothing left to lock: resolves at W1 expiry, no empty re-roll or windows")
	_check(r.window_remaining_s == ([0.0, 0.0, 0.0] as Array[float]),
		"Nothing left to lock: skipped windows credited 0 s (%s)" % [r.window_remaining_s])
	_check(is_equal_approx(_score(scene, r).heat, 1.0), "Nothing left to lock: Heat stays x1.0")
	var shattered_n := range(r.faces.size()).filter(func(i: int) -> bool: return r.shattered[i])
	_check(shattered_n.size() == 5 and shattered_n.all(func(i: int) -> bool: return scene._tumbler.dead[i]),
		"Nothing left to lock: the shattered dice are drawn as dead slots")
	await _screenshot("materials_nothing_left_resolved")


func _scenario_carving() -> void:
	_section("add-carving-service")
	var seen := {}
	for attempt in 12:
		if seen.size() == 3:
			break
		var scene := await _load_run(1, func(bag: DiceBag) -> void:
			bag.add_carved(&"standard", 6, &"wild", 2)
			bag.add_carved(&"standard", 5, &"gem", 2)
			bag.add_carved(&"standard", 4, &"spark", 2))
		var activated: Array[StringName] = []
		scene._controller.carve_activated.connect(func(_i: int, t: StringName) -> void: activated.append(t))
		_press(scene._throw_button)
		await _wait(func() -> bool: return scene._controller.state == ThrowController.State.LOCK_WINDOW)
		var ctrl: ThrowController = scene._controller
		for i in ctrl.faces.size():
			var d: DiceBag.Die = ctrl._drawn[i]
			if d.carved_face != ctrl.faces[i] or seen.has(d.carve_type):
				continue
			if d.carve_type == &"spark":  # spec scenario: Spark late in the window (0.8 s left)
				await _wait(func() -> bool: return ctrl.time_remaining() <= 0.8)
			var before := ctrl.time_remaining()
			_tap_die(scene, i)
			var after := ctrl.time_remaining()
			if d.carve_type == &"spark":
				_check(after > before + 0.3, "Spark: locking the Spark face extends the window (%.2fs → %.2fs)" % [before, after])
				await _screenshot("carving_spark_extends")
			seen[d.carve_type] = true
		await _lock_all(scene)
		await _wait(func() -> bool: return ctrl.state == ThrowController.State.RESOLVED)
		var r: ThrowResult = ctrl.last_result
		var b := _score(scene, r)
		if &"gem" in activated:
			_check(b.bonus_chips >= 20, "Gem: locked Gem face adds +20 chips (bonus_chips %d)" % b.bonus_chips)
		if &"wild" in activated:
			var wild_i := r.carve_types.find(&"wild")
			_check(_in_combos(b, wild_i), "Wild: the Wild die joins a combo (%s)" % b.describe())
			var expected_pips := 0  # Bone only: combo dice at their combo value, loose dice at their face
			for c in b.combos:
				for f: int in c["faces"]:
					expected_pips += f
			for li in b.loose_indices:
				expected_pips += r.faces[li]
			_check(b.pips == expected_pips,
				"Wild: pips use the substituted value (%d, printed face %d)" % [b.pips, r.faces[wild_i]])
			await _screenshot("carving_wild_scored")
		if &"gem" in activated:
			await _screenshot("carving_gem_scored")
	for t: StringName in [&"wild", &"gem", &"spark"]:
		_check(seen.has(t), "%s face came up and was locked within 12 throws" % t)


func _scenario_trinkets() -> void:
	_section("add-trinkets")
	var scene := await _load_run(1, func(_bag: DiceBag) -> void:
		_rc.trinket_inventory.add_trinket(load("res://resources/trinkets/re_tumble.tres"))
		_rc.trinket_inventory.add_trinket(load("res://resources/trinkets/freeze_timer.tres")))
	_press(scene._throw_button)
	await _wait(func() -> bool: return scene._controller.state == ThrowController.State.LOCK_WINDOW)
	await process_frame
	var ctrl: ThrowController = scene._controller
	_check(scene._trinket_row.visible and scene._trinket_row.get_child_count() == 2,
		"Trinket buttons shown during the lock window")
	await _screenshot("trinkets_buttons")
	var before := ctrl.faces.duplicate()
	var rerolled: Array = []
	ctrl.reroll_started.connect(func(idx: Array[int]) -> void: rerolled.append_array(idx))
	_press(scene._trinket_row.get_child(0))  # Re-Tumble
	_check(rerolled.size() == before.size(), "Re-Tumble re-rolls every unlocked die (%d)" % rerolled.size())
	_check(ctrl.state == ThrowController.State.LOCK_WINDOW, "Re-Tumble keeps the window open")
	# spec scenario: Freeze Timer with 0.5 s left
	await _wait(func() -> bool: return ctrl.time_remaining() <= 0.5)
	var t_before := ctrl.time_remaining()
	_press(scene._trinket_row.get_child(0))  # Freeze Timer (now first after Re-Tumble was consumed)
	var t_after := ctrl.time_remaining()
	_check(t_after >= t_before + 1.9, "Freeze Timer extends the window by 2 s (%.2fs → %.2fs)" % [t_before, t_after])
	await process_frame
	await _screenshot("trinkets_after_freeze")
	_check(_rc.trinket_inventory.iter_trinkets().is_empty(), "Both trinkets consumed")


func _scenario_boss() -> void:
	_section("add-boss-modifier")
	var scene := await _load_run(3, Callable())
	_check("BOSS ROUND" in scene._ante_label.text, "Ante 3 label reads '%s'" % scene._ante_label.text)
	_press(scene._throw_button)
	await _wait(func() -> bool: return scene._controller.state == ThrowController.State.LOCK_WINDOW)
	await _screenshot("boss_window")
	var t0 := Time.get_ticks_msec()
	await _wait(func() -> bool: return scene._controller.state == ThrowController.State.REROLL)
	var window_s := (Time.get_ticks_msec() - t0) / 1000.0
	_check(absf(window_s - 1.25) < 0.15, "Boss lock window lasts ~1.25s, half of 2.5s (measured %.2fs)" % window_s)


func _scenario_risk_skip() -> void:
	_section("add-risk-skip")
	var scene := await _load_run(2, Callable())
	_check(scene._skip_button.visible, "SKIP button visible on the Risk ante")
	_check(not scene._skip_button.get_global_rect().intersects(scene._throw_button.get_global_rect()),
		"SKIP and THROW buttons don't overlap")
	_check("RISK ROUND" in scene._ante_label.text, "Ante 2 label reads '%s'" % scene._ante_label.text)
	await _screenshot("risk_skip_button")
	var gold_before: int = _rc.ledger.gold
	_press(scene._skip_button)
	await _wait(func() -> bool: return current_scene != null and current_scene.scene_file_path == SHOP_SCENE)
	await process_frame
	_check(current_scene.scene_file_path == SHOP_SCENE, "SKIP goes to the Shop")
	_check(_rc.ledger.gold == gold_before + 3, "SKIP pays 3 gold (%d → %d)" % [gold_before, _rc.ledger.gold])
	_check(_rc.arc.current_ante == 3, "After the Shop the run continues at ante 3")
	await _screenshot("risk_skip_shop")
	var no_skip := await _load_run(1, Callable())
	_check(not no_skip._skip_button.visible, "No SKIP button on a non-Risk ante")


func _scenario_juice() -> void:
	_section("add-juice-pass")
	var scene := await _load_run(1, Callable())
	var locks: Array[int] = []  # lambdas capture ints by value; append to a shared array
	scene._controller.die_locked.connect(func(i: int, _w: int) -> void: locks.append(i))
	_press(scene._throw_button)
	await _wait(func() -> bool: return scene._controller.state == ThrowController.State.LOCK_WINDOW)
	await _lock_all(scene)
	_check(locks.size() == scene._controller.faces.size(),
		"Lock haptic path ran for every lock (%d); Input.vibrate_handheld is a no-op on desktop" % locks.size())
	await _wait(func() -> bool: return scene._controller.state == ThrowController.State.RESOLVED)
	var b := _score(scene, scene._controller.last_result)
	var max_offset := 0.0
	var t0 := Time.get_ticks_msec()
	while Time.get_ticks_msec() - t0 < 400:
		max_offset = maxf(max_offset, absf(scene.position.x))
		await process_frame
	if b.combos.is_empty():
		_check(max_offset == 0.0, "No combo → no shake")
	else:
		_check(max_offset > 2.0, "Combo landed (%s) → screen shook (max offset %.1f px)" % [b.describe(), max_offset])
	_check(scene.position == Vector2.ZERO, "Shake settles back to the origin")
	await _screenshot("juice_after_shake")


# ----------------------------------------------------------------- helpers
func _load_run(ante: int, setup: Callable) -> Control:
	paused = false
	_rc.start_run()
	_rc.arc.current_ante = ante
	if setup.is_valid():
		_rc.bag._dice.clear()
		setup.call(_rc.bag)
		if _rc.bag._dice.is_empty():
			_rc.bag.add(DiceBag.STANDARD_MAT, 6)
	change_scene_to_file(THROW_SCENE)
	await process_frame
	await process_frame
	var scene := current_scene as Control
	_log("  · seed %d, ante %d" % [_rng.run_seed, ante])
	return scene


func _press(button: Button) -> void:
	button.pressed.emit()


## A real tap: press + release events pushed through the viewport, so they take the
## full path (GUI routing → ThrowScene._gui_input → tap forgiveness → lock).
func _tap_die(scene: Control, index: int) -> void:
	var center: Vector2 = scene._tumbler.die_rect(index).get_center()
	for pressed: bool in [true, false]:
		var ev := InputEventMouseButton.new()
		ev.button_index = MOUSE_BUTTON_LEFT
		ev.pressed = pressed
		ev.position = center
		ev.global_position = center
		root.push_input(ev, true)


func _lock_all(scene: Control) -> void:
	var ctrl: ThrowController = scene._controller
	for i in ctrl.faces.size():
		if ctrl.state != ThrowController.State.LOCK_WINDOW:
			return
		if not ctrl.locked[i] and not ctrl._shattered[i]:
			_tap_die(scene, i)
			await process_frame


func _indices_of(ctrl: ThrowController, material: StringName) -> Array[int]:
	var out: Array[int] = []
	for i in ctrl.faces.size():
		if ctrl._drawn[i].material_id == material:
			out.append(i)
	return out


func _score(scene: Control, r: ThrowResult) -> ScoreBreakdown:
	return scene._scoring.score(r, scene._scoring_config, scene._effective_window_s, false, _rc.inventory)


func _in_combos(b: ScoreBreakdown, index: int) -> bool:
	for c in b.combos:
		if index in c["dice_indices"]:
			return true
	return false


func _wait(cond: Callable) -> void:
	var t0 := Time.get_ticks_msec()
	var beat := t0
	while not cond.call():
		if Time.get_ticks_msec() - beat > 2000:
			beat = Time.get_ticks_msec()
			var sc := current_scene
			print("    … waiting %.1fs, scene=%s paused=%s state=%s" % [(beat - t0) / 1000.0, sc.name if sc else "none",
				paused, sc._controller.state if sc and "_controller" in sc and sc._controller else "-"])
		if Time.get_ticks_msec() - t0 > TIMEOUT_S * 1000.0:
			_check(false, "timed out waiting")
			return
		await process_frame


func _screenshot(label: String) -> void:
	await process_frame
	_shot += 1
	var path := OUT_DIR + "%02d_%s.png" % [_shot, label]
	root.get_texture().get_image().save_png(path)
	_log("  · screenshot `%s`" % path.get_file())


func _section(name: String) -> void:
	_log("\n## %s" % name)


func _check(ok: bool, what: String) -> void:
	if not ok:
		_failures += 1
	_log("- [%s] %s" % ["x" if ok else " ", what])


func _log(line: String) -> void:
	_report.append(line)
	print(line)
