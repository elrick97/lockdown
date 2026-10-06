extends Control
## Presentation for the throw loop (Smoke Room UI, ui-theme spec). All gameplay decisions live in
## ThrowController; this scene renders state, resolves taps to die indices
## (geometry never reaches the controller), and handles focus-loss pause.

signal ante_cleared(throws_left: int)

const TIMER_BAR_FULL_WIDTH := 1000.0
const MAX_COUNTDOWN_STEP_S := 0.1
const START_SCENE := "res://scenes/start/start_scene.tscn"
const CHARM_SLOTS := 5
const FELT := preload("res://assets/table/felt.png")

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
var _end_panel: ColorRect
var _end_title: Label
var _end_summary: Label
var _new_run_button: Button
var _menu_button: Button
var _hud_panel: Panel
var _timer_track: ColorRect
var _charm_row: HBoxContainer
var _charm_slots: Array[Button] = []
var _felt: TextureRect

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
	theme = UiStyle.theme()
	_hud_panel = Panel.new()
	_hud_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_hud_panel)
	move_child(_hud_panel, 0)
	_timer_track = ColorRect.new()
	_timer_track.color = Color(0.1, 0.06, 0.05)
	_timer_track.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_timer_track)
	move_child(_timer_track, _timer_bar.get_index())
	_timer_bar.color = UiStyle.AMBER
	_total_label.theme_type_variation = &"HudValue"
	_result.theme_type_variation = &"HudValue"
	_throw_button.theme_type_variation = &"ThrowButton"
	_charm_row = HBoxContainer.new()
	_charm_row.add_theme_constant_override("separation", 20)
	add_child(_charm_row)
	SmokeOverlay.add_backdrop(self)
	SmokeOverlay.add_to(self)
	# Felt with the lamp pool painted in, behind the dice (art-direction spec).
	_felt = TextureRect.new()
	_felt.texture = FELT
	_felt.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_felt.stretch_mode = TextureRect.STRETCH_SCALE
	_felt.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tray.add_child(_felt)
	_felt.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
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
	_build_end_panel()
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
	_build_charm_row()

	_update_round_labels()
	_status.text = "Tap THROW to roll the dice"


## Establish the UI layout in code. The hand-authored .tscn loses all Control
## anchor/offset values through the Android export step (they survive a desktop
## source-load but reset to defaults in the exported binary scene), so we drive
## the layout at runtime where it is guaranteed to apply on every platform.
func _apply_layout() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	# Bands at 1080×2400 (ui-theme spec, design D2).
	if _hud_panel != null:
		_set_rect(_hud_panel, 0.0, 0.0, 1.0, 0.0, 24.0, 20.0, -24.0, 250.0)
	_set_rect(_ante_label, 0.0, 0.0, 1.0, 0.0, 40.0, 34.0, -40.0, 124.0)
	_set_rect(_throw_label, 0.0, 0.0, 0.5, 0.0, 40.0, 134.0, 0.0, 234.0)
	_set_rect(_total_label, 0.5, 0.0, 1.0, 0.0, 0.0, 134.0, -40.0, 234.0)
	_set_rect(_status, 0.0, 0.0, 1.0, 0.0, 40.0, 270.0, -40.0, 360.0)
	_set_rect(_result, 0.0, 0.0, 1.0, 0.0, 40.0, 370.0, -40.0, 600.0)
	if _timer_track != null:
		_set_rect(_timer_track, 0.0, 0.0, 0.0, 0.0, 40.0, 615.0, 1040.0, 650.0)
	_set_rect(_timer_bar, 0.0, 0.0, 0.0, 0.0, 40.0, 615.0, 1040.0, 650.0)
	_set_rect(_tray, 0.0, 0.27, 1.0, 0.66, 0.0, 0.0, 0.0, 0.0)
	if _charm_row != null:
		_set_rect(_charm_row, 0.0, 0.0, 1.0, 0.0, 40.0, 1610.0, -40.0, 1770.0)
	_set_rect(_throw_button, 0.5, 1.0, 0.5, 1.0, -260.0, -300.0, 260.0, -120.0)
	# SKIP (before the first throw on a Risk ante) and trinkets (during lock windows)
	# never show together, so they share the row above THROW.
	if _skip_button != null:
		_set_rect(_skip_button, 0.5, 0.0, 0.5, 0.0, -260.0, 1800.0, 260.0, 1930.0)
	if _trinket_row != null:
		_set_rect(_trinket_row, 0.0, 0.0, 1.0, 0.0, 40.0, 1800.0, -40.0, 1930.0)
	if _end_panel != null:
		_end_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		_set_rect(_end_title, 0.0, 0.0, 1.0, 0.0, 40.0, 620.0, -40.0, 760.0)
		_set_rect(_end_summary, 0.0, 0.0, 1.0, 0.0, 40.0, 800.0, -40.0, 1100.0)
		_set_rect(_new_run_button, 0.0, 1.0, 0.5, 1.0, 40.0, -300.0, -20.0, -120.0)
		_set_rect(_menu_button, 0.5, 1.0, 1.0, 1.0, 20.0, -300.0, -40.0, -120.0)
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
		# Capped step: the first frame after a hidden browser tab can carry seconds of
		# delta, which would skip the 3-2-1 countdown entirely.
		_countdown_left -= minf(delta, MAX_COUNTDOWN_STEP_S)
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
	# Use the event's own position (local to this Control) in the die rects' global
	# space; never the OS cursor. Touch arrives as emulated mouse events, and the
	# global transform also follows the screen-shake offset.
	_try_lock_at(get_global_transform() * mb.position)


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
	_tumbler.build(_controller.drawn_dice())
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
		btn.custom_minimum_size.y = 130.0  # ui-theme spec: ≥ 48 dp
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
	RunCoordinator.record_throw(_cascade.final_score)
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
	_show_end_panel(true)


func _on_run_lost() -> void:
	_update_round_labels()
	_status.text = "GAME OVER."
	_throw_button.disabled = true
	_show_end_panel(false)


## End-of-run panel (run-flow spec): result, summary, NEW RUN / MENU. Sits above the
## tray and below the focus cover, so focus loss still covers everything.
func _build_end_panel() -> void:
	_end_panel = ColorRect.new()
	_end_panel.color = Color(0.02, 0.01, 0.01, 0.86)
	_end_panel.visible = false
	add_child(_end_panel)
	move_child(_end_panel, _cover.get_index())
	_end_title = _end_label(76)
	_end_summary = _end_label(46)
	_new_run_button = _end_button("NEW RUN")
	_new_run_button.pressed.connect(_on_new_run_pressed)
	_menu_button = _end_button("MENU")
	_menu_button.pressed.connect(_on_menu_pressed)


func _end_label(font_size: int) -> Label:
	var l := Label.new()
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", font_size)
	_end_panel.add_child(l)
	return l


func _end_button(text: String) -> Button:
	var b := Button.new()
	b.text = text
	b.add_theme_font_size_override("font_size", 44)
	_end_panel.add_child(b)
	return b


## Owned charms (ui-theme spec): names in slot order; tapping one shows its effect.
func _build_charm_row() -> void:
	for child in _charm_row.get_children():
		child.queue_free()
	_charm_slots.clear()
	var charms := RunCoordinator.inventory.iter_charms()
	for i in CHARM_SLOTS:
		var slot := Button.new()
		slot.theme_type_variation = &"SlotButton"
		slot.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		slot.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		slot.clip_text = true
		if i < charms.size():
			var charm: CharmEffect = charms[i]
			slot.text = charm.display_name
			slot.pressed.connect(func() -> void:
				_status.text = "%s: %s" % [charm.display_name, charm.description])
		else:
			slot.text = "·"
			slot.disabled = true
		_charm_row.add_child(slot)
		_charm_slots.append(slot)


func _show_end_panel(won: bool) -> void:
	_end_title.text = "RUN WON" if won else "GAME OVER"
	_end_summary.text = "Ante %d / %d\nBest throw  %d\nFinal total  %d / %d\n\nSeed %d" % [
		_arc.current_ante, _ante_config.targets.size(), RunCoordinator.best_throw,
		_round.total, _round.target, RngService.run_seed]
	_skip_button.visible = false
	_end_panel.visible = true


func _on_new_run_pressed() -> void:
	RunCoordinator.new_run()
	get_tree().change_scene_to_file("res://scenes/throw/throw_scene.tscn")


func _on_menu_pressed() -> void:
	RunCoordinator.end_run()
	get_tree().change_scene_to_file(START_SCENE)


func _notification(what: int) -> void:
	match what:
		# Window focus covers the web (a tab blur sends no application notification);
		# duplicates on other platforms are absorbed by the _focus_paused guard.
		NOTIFICATION_APPLICATION_FOCUS_OUT, NOTIFICATION_APPLICATION_PAUSED, NOTIFICATION_WM_WINDOW_FOCUS_OUT:
			_on_focus_lost()
		NOTIFICATION_APPLICATION_FOCUS_IN, NOTIFICATION_APPLICATION_RESUMED, NOTIFICATION_WM_WINDOW_FOCUS_IN:
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
