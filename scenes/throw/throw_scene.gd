extends Control
## Gray-box presentation for the throw loop. All gameplay decisions live in
## ThrowController; this scene renders state, resolves taps to die indices
## (geometry never reaches the controller), and handles focus-loss pause.

signal ante_cleared(throws_left: int)

const TIMER_BAR_FULL_WIDTH := 1000.0

var _config: ThrowConfig = preload("res://resources/throw_config.tres")
var _scoring_config: ScoringConfig = preload("res://resources/scoring_config.tres")
var _ante_config: AnteConfig = preload("res://resources/ante_arc.tres")
var _scoring := ScoringEngine.new()
var _bag: DiceBag
var _controller: ThrowController
var _arc: AnteArc
var _round: RoundState
var _tumbler: DiceTumbler
var _cascade: ScoreCascade
var _countdown_left := -1.0
var _focus_paused := false
var _effective_window_s: float
var _skip_button: Button
var _trinket_row: HBoxContainer
var _sfx_lock: AudioStreamPlayer
var _sfx_combo: AudioStreamPlayer

@onready var _tray: Control = $Tray
@onready var _timer_bar: ColorRect = $TimerBar
@onready var _status: Label = $Status
@onready var _result: Label = $Result
@onready var _throw_button: Button = $ThrowButton
@onready var _cover: ColorRect = $FocusCover
@onready var _countdown_label: Label = $FocusCover/Countdown
@onready var _ante_label: Label = $AnteLabel
@onready var _throw_label: Label = $ThrowLabel
@onready var _total_label: Label = $TotalLabel


func _ready() -> void:
	_skip_button = Button.new()
	_skip_button.text = "SKIP RISK (+3g)"
	_skip_button.add_theme_font_size_override("font_size", 40)
	add_child(_skip_button)
	_trinket_row = HBoxContainer.new()
	_trinket_row.visible = false
	add_child(_trinket_row)
	_sfx_lock = AudioStreamPlayer.new()
	add_child(_sfx_lock)
	_sfx_combo = AudioStreamPlayer.new()
	add_child(_sfx_combo)
	_apply_layout()
	get_viewport().size_changed.connect(_apply_layout)

	if RunCoordinator.arc == null:
		RunCoordinator.start_run()
	_arc = RunCoordinator.arc
	_arc.ante_advanced.connect(_on_ante_advanced)
	_arc.run_won.connect(_on_run_won)
	_arc.run_lost.connect(_on_run_lost)
	ante_cleared.connect(RunCoordinator.on_ante_cleared)

	_effective_window_s = _window_s_for(_arc.current_ante)
	_bag = RunCoordinator.bag
	_controller = _make_controller()
	_throw_button.pressed.connect(_on_throw_pressed)
	_skip_button.visible = _ante_config.risk_antes.has(_arc.current_ante)
	_skip_button.pressed.connect(RunCoordinator.on_risk_skipped)
	_timer_bar.visible = false

	_round = RoundState.new(_arc.target_for(_arc.current_ante), _ante_config.throws_per_round)
	_round.round_won.connect(_on_round_won)
	_round.round_lost.connect(_on_round_lost)

	_tumbler = Viewport3DDiceTumbler.new()
	_tray.add_child(_tumbler)

	_update_round_labels()
	_status.text = "Seed %d — press THROW" % RngService.run_seed


## Establish the UI layout in code. The hand-authored .tscn loses all Control
## anchor/offset values through the Android export step (they survive a desktop
## source-load but reset to defaults in the exported binary scene), so we drive
## the layout at runtime where it is guaranteed to apply on every platform.
func _apply_layout() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_set_rect(_ante_label, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 110.0)
	_set_rect(_throw_label, 0.0, 0.0, 0.5, 0.0, 0.0, 115.0, 0.0, 200.0)
	_set_rect(_total_label, 0.5, 0.0, 1.0, 0.0, 0.0, 115.0, 0.0, 200.0)
	_set_rect(_status, 0.0, 0.0, 1.0, 0.0, 0.0, 210.0, 0.0, 330.0)
	_set_rect(_result, 0.0, 0.0, 1.0, 0.0, 40.0, 340.0, -40.0, 590.0)
	_set_rect(_timer_bar, 0.0, 0.0, 0.0, 0.0, 40.0, 600.0, 1040.0, 635.0)
	_set_rect(_tray, 0.0, 0.25, 1.0, 0.75, 0.0, 0.0, 0.0, 0.0)
	_set_rect(_throw_button, 0.5, 1.0, 0.5, 1.0, -220.0, -300.0, 220.0, -120.0)
	if _skip_button != null:
		# Own row directly above THROW: in thumb reach, never overlapping it.
		_set_rect(_skip_button, 0.5, 1.0, 0.5, 1.0, -220.0, -440.0, 220.0, -320.0)
	if _trinket_row != null:
		_set_rect(_trinket_row, 0.0, 0.0, 1.0, 0.0, 40.0, 645.0, -40.0, 780.0)
	_cover.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_countdown_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func _set_rect(c: Control, al: float, at: float, ar: float, ab: float,
		ol: float, ot: float, orr: float, ob: float) -> void:
	c.anchor_left = al
	c.anchor_top = at
	c.anchor_right = ar
	c.anchor_bottom = ab
	c.offset_left = ol
	c.offset_top = ot
	c.offset_right = orr
	c.offset_bottom = ob


func _process(delta: float) -> void:
	if _countdown_left >= 0.0:
		_countdown_left -= delta
		_countdown_label.text = str(ceili(maxf(_countdown_left, 0.001)))
		if _countdown_left <= 0.0:
			_countdown_left = -1.0
			_cover.visible = false
			get_tree().paused = false
			_controller.restart_window()
		return
	if get_tree().paused:
		return
	_controller.tick(delta)
	_update_visuals()


func _update_visuals() -> void:
	match _controller.state:
		ThrowController.State.TUMBLE, ThrowController.State.REROLL:
			_timer_bar.visible = false
			_trinket_row.visible = false
			_tumbler.tick(get_process_delta_time())
		ThrowController.State.LOCK_WINDOW:
			_timer_bar.visible = true
			_trinket_row.visible = true
			var fraction := _controller.time_remaining() / _effective_window_s
			_timer_bar.size.x = TIMER_BAR_FULL_WIDTH * fraction
		_:
			pass


func _gui_input(event: InputEvent) -> void:
	if get_tree().paused or _focus_paused:
		return
	var mb := event as InputEventMouseButton
	if mb == null or not mb.pressed or mb.button_index != MOUSE_BUTTON_LEFT:
		return
	_try_lock_at(get_global_mouse_position())


## Tap forgiveness (throw-loop spec): lock the nearest unlocked die whose
## bounds are within tap_forgiveness_radius_px of the tap point.
func _try_lock_at(point: Vector2) -> void:
	if _tumbler == null:
		return
	var best := -1
	var best_dist := INF
	for i in _controller.faces.size():
		if _controller.locked[i] or _controller.is_shattered(i):
			continue
		var rect := _tumbler.die_rect(i)
		var clamped := point.clamp(rect.position, rect.end)
		var dist := point.distance_to(clamped)
		if dist < best_dist:
			best_dist = dist
			best = i
	if best >= 0 and best_dist <= _config.tap_forgiveness_radius_px:
		_controller.lock_die(best)


func _on_throw_pressed() -> void:
	_result.text = ""
	_result.scale = Vector2.ONE  # reset in case previous cascade was interrupted
	_throw_button.disabled = true
	_skip_button.visible = false
	_rebuild_trinket_buttons()
	_controller.start_throw()
	_tumbler.build(_controller.faces.size())
	_tumbler.begin_tumble(_controller.faces, _controller.locked, _tumble_duration_s())
	_status.text = "Tumbling…"


func _rebuild_trinket_buttons() -> void:
	for child in _trinket_row.get_children():
		child.queue_free()
	if RunCoordinator.trinket_inventory == null:
		return
	var trinkets := RunCoordinator.trinket_inventory.iter_trinkets()
	for i in trinkets.size():
		var t: Trinket = trinkets[i]
		var btn := Button.new()
		btn.text = t.display_name
		btn.add_theme_font_size_override("font_size", 36)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_trinket_row.add_child(btn)
		var idx := i
		btn.pressed.connect(func() -> void:
			var consumed: Trinket = RunCoordinator.trinket_inventory.consume(idx)
			if consumed != null:
				consumed.activate(_controller)
				_rebuild_trinket_buttons()
		)


func _tumble_duration_s() -> float:
	return _controller.tumble_duration()


func _window_s_for(ante: int) -> float:
	if _ante_config.boss_antes.has(ante):
		return _config.lock_window_duration_s * _ante_config.boss_window_scale
	return _config.lock_window_duration_s


func _make_controller() -> ThrowController:
	var effective_config := _config.duplicate() as ThrowConfig
	effective_config.lock_window_duration_s = _effective_window_s
	var ctrl := ThrowController.new(effective_config, _bag, RngService.get_core(), RunCoordinator.inventory)
	ctrl.window_started.connect(_on_window_started)
	ctrl.die_locked.connect(_on_die_locked)
	ctrl.reroll_started.connect(_on_reroll_started)
	ctrl.carve_activated.connect(_on_carve_activated)
	ctrl.resolved.connect(_on_resolved)
	return ctrl


func _update_round_labels() -> void:
	var round_name := ""
	if _arc.current_ante - 1 < _ante_config.round_names.size():
		round_name = " — %s ROUND" % _ante_config.round_names[_arc.current_ante - 1].to_upper()
	_ante_label.text = "ANTE %d / %d%s" % [_arc.current_ante, _ante_config.targets.size(), round_name]
	_throw_label.text = "Throw %d / %d" % [_round.current_throw, _ante_config.throws_per_round]
	_total_label.text = "Total: %d / %d" % [_round.total, _round.target]


func _on_window_started(window_index: int) -> void:
	_tumbler.reveal(_controller.faces, _controller.locked)
	_status.text = "Window %d / 3 — TAP TO LOCK" % window_index


func _on_die_locked(die_index: int, _window_index: int) -> void:
	_tumbler.lock_die(die_index, _controller.faces[die_index])
	Input.vibrate_handheld(30)
	if _sfx_lock != null and _sfx_lock.stream != null:
		_sfx_lock.play()


func _on_reroll_started(_rerolled_indices: Array[int]) -> void:
	_mark_dead_slots()
	_tumbler.begin_tumble(_controller.faces, _controller.locked, _tumble_duration_s())
	_status.text = "Re-rolling…"


## Shattered Glass is drawn as a dead slot. Called on every re-roll and on resolve,
## because a re-roll that leaves nothing to lock resolves without re-rolling.
func _mark_dead_slots() -> void:
	for i in _controller.faces.size():
		if _controller.is_shattered(i):
			_tumbler.mark_dead(i)


func _on_carve_activated(_die_index: int, carve_type: StringName) -> void:
	if carve_type == &"spark":
		_controller.freeze_window(0.5)


func _screen_shake(amplitude: float, duration: float) -> void:
	var tween := create_tween()
	var steps := 6
	for i in steps:
		var t := duration / steps
		var sign := 1.0 if i % 2 == 0 else -1.0
		var decay := 1.0 - float(i) / steps
		tween.tween_property(self, "position",
			Vector2(sign * amplitude * decay, 0.0), t * 0.5)
		tween.tween_property(self, "position", Vector2.ZERO, t * 0.5)


func _on_resolved(result: ThrowResult) -> void:
	_timer_bar.visible = false
	_mark_dead_slots()
	_tumbler.reveal(_controller.faces, _controller.locked)
	var breakdown := _scoring.score(result, _scoring_config, _effective_window_s, false, RunCoordinator.inventory)
	if not breakdown.combos.is_empty():
		_screen_shake(8.0, 0.25)
		if _sfx_combo != null and _sfx_combo.stream != null:
			_sfx_combo.play()
	var old_total := _round.total
	var new_total := old_total + breakdown.final_score
	_cascade = ScoreCascade.new(self, _tumbler, _result, _total_label, _scoring_config)
	_cascade.finished.connect(_on_cascade_finished)
	_cascade.play(breakdown, old_total, new_total, _round.target)


func _on_cascade_finished() -> void:
	_round.add_score(_cascade.final_score)
	if _round.is_done:
		return  # _on_round_won/lost → _on_ante_advanced/_on_run_* already updated labels + button
	_update_round_labels()
	var throws_left := _ante_config.throws_per_round - _round.current_throw
	_status.text = "Score %d — %d throw(s) left" % [_cascade.final_score, throws_left]
	_throw_button.disabled = false


func _on_round_won() -> void:
	_arc.on_round_won()


func _on_round_lost() -> void:
	_arc.on_round_lost()


func _on_ante_advanced(_new_ante: int, _new_target: int) -> void:
	var throws_left := _ante_config.throws_per_round - _round.current_throw
	_throw_button.disabled = true
	ante_cleared.emit(throws_left)


func _on_run_won() -> void:
	_update_round_labels()
	_status.text = "YOU WIN!"
	_throw_button.disabled = true


func _on_run_lost() -> void:
	_update_round_labels()
	_status.text = "GAME OVER."
	_throw_button.disabled = true


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_APPLICATION_FOCUS_OUT, NOTIFICATION_APPLICATION_PAUSED:
			_on_focus_lost()
		NOTIFICATION_APPLICATION_FOCUS_IN, NOTIFICATION_APPLICATION_RESUMED:
			_on_focus_returned()


func _on_focus_lost() -> void:
	if _focus_paused or not is_inside_tree():
		return
	_focus_paused = true
	_countdown_left = -1.0
	get_tree().paused = true
	_cover.visible = true
	_countdown_label.text = ""


func _on_focus_returned() -> void:
	if not _focus_paused:
		return
	_focus_paused = false
	_countdown_left = _config.resume_countdown_s
