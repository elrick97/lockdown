extends Control
## Gray-box presentation for the throw loop. All gameplay decisions live in
## ThrowController; this scene renders state, resolves taps to die indices
## (geometry never reaches the controller), and handles focus-loss pause.

const TIMER_BAR_FULL_WIDTH := 1000.0

var _config: ThrowConfig = preload("res://resources/throw_config.tres")
var _scoring_config: ScoringConfig = preload("res://resources/scoring_config.tres")
var _ante_config: AnteConfig = preload("res://resources/ante_arc.tres")
var _scoring := ScoringEngine.new()
var _bag: DiceBag
var _controller: ThrowController
var _arc: AnteArc
var _round: RoundState
var _pending_target: int = 0
var _tumbler: DiceTumbler
var _countdown_left := -1.0
var _focus_paused := false

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
	_apply_layout()
	get_viewport().size_changed.connect(_apply_layout)
	RngService.start_run()
	_bag = DiceBag.new(_config.starting_bag_size)
	_controller = ThrowController.new(_config, _bag, RngService.get_core())
	_controller.window_started.connect(_on_window_started)
	_controller.die_locked.connect(_on_die_locked)
	_controller.reroll_started.connect(_on_reroll_started)
	_controller.resolved.connect(_on_resolved)
	_throw_button.pressed.connect(_on_throw_pressed)
	_timer_bar.visible = false

	_arc = AnteArc.new(_ante_config)
	_arc.ante_advanced.connect(_on_ante_advanced)
	_arc.run_won.connect(_on_run_won)
	_arc.run_lost.connect(_on_run_lost)

	_round = RoundState.new(_arc.target_for(1), _ante_config.throws_per_round)
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
			_tumbler.tick(get_process_delta_time())
		ThrowController.State.LOCK_WINDOW:
			_timer_bar.visible = true
			var fraction := _controller.time_remaining() / _config.lock_window_duration_s
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
		if _controller.locked[i]:
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
	if _pending_target > 0:
		_round.reset(_pending_target)  # reuses same object; signals stay connected
		_pending_target = 0
	_result.text = ""
	_throw_button.disabled = true
	_controller.start_throw()
	_tumbler.build(_controller.faces.size())
	_tumbler.begin_tumble(_controller.faces, _controller.locked, _config.tumble_duration_s)
	_status.text = "Tumbling…"


func _update_round_labels() -> void:
	_ante_label.text = "ANTE %d / %d" % [_arc.current_ante, _ante_config.targets.size()]
	_throw_label.text = "Throw %d / %d" % [_round.current_throw, _ante_config.throws_per_round]
	_total_label.text = "Total: %d / %d" % [_round.total, _round.target]


func _on_window_started(window_index: int) -> void:
	_tumbler.reveal(_controller.faces, _controller.locked)
	_status.text = "Window %d / 3 — TAP TO LOCK" % window_index


func _on_die_locked(die_index: int, _window_index: int) -> void:
	_tumbler.lock_die(die_index, _controller.faces[die_index])


func _on_reroll_started(_rerolled_indices: Array[int]) -> void:
	_tumbler.begin_tumble(_controller.faces, _controller.locked, _config.tumble_duration_s)
	_status.text = "Re-rolling…"


func _on_resolved(result: ThrowResult) -> void:
	_timer_bar.visible = false
	_tumbler.reveal(_controller.faces, _controller.locked)
	var breakdown := _scoring.score(result, _scoring_config, 0, _config.lock_window_duration_s, false)
	_result.text = breakdown.describe()
	_round.add_score(breakdown.final_score)
	_update_round_labels()
	if _round.is_done:
		return  # round_won or round_lost signal already handled button + status
	var throws_left := _ante_config.throws_per_round - _round.current_throw
	_status.text = "Score %d — %d throw(s) left" % [breakdown.final_score, throws_left]
	_throw_button.disabled = false


func _on_round_won() -> void:
	_arc.on_round_won()


func _on_round_lost() -> void:
	_arc.on_round_lost()


func _on_ante_advanced(new_ante: int, new_target: int) -> void:
	_pending_target = new_target
	_ante_label.text = "ANTE %d / %d" % [new_ante, _ante_config.targets.size()]
	_throw_label.text = "Throw 0 / %d" % _ante_config.throws_per_round
	_total_label.text = "Total: 0 / %d" % new_target
	_status.text = "Ante %d cleared! Press THROW for ante %d." % [new_ante - 1, new_ante]
	_throw_button.disabled = false


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
