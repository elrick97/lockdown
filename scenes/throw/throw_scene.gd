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
const URGENT_TINT := Color(1.0, 0.22, 0.18)
## Inspect card bottom edges (canvas units): above the charm row / the end-panel build.
const INSPECT_ABOVE_SLOTS_Y := 1590.0
const INSPECT_ABOVE_BUILD_Y := 1150.0

var _config: ThrowConfig = preload("res://resources/throw_config.tres")
var _scoring_config: ScoringConfig = preload("res://resources/scoring_config.tres")
var _ante_config: AnteConfig = preload("res://resources/ante_arc.tres")
var _fx: FeedbackConfig = preload("res://resources/feedback_config.tres")
var _hud: ScoreHud
var _timer_fill: NinePatchRect
var _shake_tween: Tween
var _skip_hint: Label
var _inspect: InspectCard
var _urgency_label: Label
## Ante intro card (add-ante-intro-card): target, reward and rule before throw 1.
var _intro: ColorRect
var _intro_title: Label
var _intro_target: Label
var _intro_reward: Label
var _intro_rule: Label
var _intro_play: Button
var _brief: AnteBrief
## Round-cleared panel (add-round-cashout).
var _cashout: ColorRect
var _cashout_title: Label
var _cashout_rows: VBoxContainer
var _cashout_total: Label
var _cashout_continue: Button
## Manual pause (add-pause-settings): the chip button and the menu over the cover.
var _pause_button: TextureButton
var _pause_menu: PauseMenu
var _paused_label: Label
var _menu_open := false
var _tray_tween: Tween
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
var _timer_track: NinePatchRect
var _total_plaque: Panel
var _end_card: Panel
var _end_build: HBoxContainer
var _end_score: Label
var _end_score_caption: Label
var _end_build_caption: Label
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
	# Brass tube frame + amber fill from the UI kit; the fill follows the bar's width,
	# which _update_visuals animates, so timing code is untouched.
	_timer_track = UiStyle.nine_patch("timer_frame", UiStyle.TIMER_FRAME_MARGINS)
	add_child(_timer_track)
	move_child(_timer_track, _timer_bar.get_index())
	_timer_bar.color = Color(0, 0, 0, 0)
	_timer_fill = UiStyle.nine_patch("timer_fill", UiStyle.TIMER_FILL_MARGINS)
	_timer_bar.add_child(_timer_fill)
	_timer_fill.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_total_plaque = Panel.new()
	_total_plaque.theme_type_variation = &"PlaquePanel"
	_total_plaque.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_total_plaque)
	move_child(_total_plaque, _total_label.get_index())
	_total_label.theme_type_variation = &"HudValue"
	_total_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_throw_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_result.theme_type_variation = &"HudValue"
	_result.add_theme_font_size_override("font_size", 76)
	_result.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_result.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
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
	_build_intro()
	_skip_button = Button.new()
	_skip_button.text = "SKIP RISK (+%dg)" % _ante_config.skip_reward_gold
	_skip_button.add_theme_font_size_override("font_size", 40)
	_intro.add_child(_skip_button)  # the risk trade-off lives on the intro card
	_trinket_row = HBoxContainer.new()
	_trinket_row.visible = false
	add_child(_trinket_row)
	# Shown only while the score builds up, in the (then empty) trinket row band.
	_skip_hint = Label.new()
	_skip_hint.text = "TAP TO SKIP"
	_skip_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_skip_hint.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_skip_hint.add_theme_font_size_override("font_size", 30)
	_skip_hint.add_theme_color_override("font_color", UiStyle.MUTED)
	_skip_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_skip_hint.visible = false
	add_child(_skip_hint)
	_urgency_label = Label.new()
	_urgency_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_urgency_label.add_theme_font_size_override("font_size", 40)
	_urgency_label.add_theme_color_override("font_color", UiStyle.CREAM)
	_urgency_label.add_theme_color_override("font_outline_color", UiStyle.OUTLINE)
	_urgency_label.add_theme_constant_override("outline_size", 8)
	_urgency_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_urgency_label.visible = false
	add_child(_urgency_label)
	_sfx_lock = AudioStreamPlayer.new()
	add_child(_sfx_lock)
	_sfx_combo = AudioStreamPlayer.new()
	add_child(_sfx_combo)
	_build_end_panel()
	_build_cashout()
	_pause_button = UiStyle.icon_button("icon_pause")
	_pause_button.pressed.connect(open_pause)
	add_child(_pause_button)
	_pause_menu = PauseMenu.new()
	_pause_menu.resume_requested.connect(_on_pause_resume)
	_pause_menu.abandon_confirmed.connect(_on_abandon)
	add_child(_pause_menu)
	_paused_label = Label.new()
	_paused_label.text = "PAUSED"
	_paused_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_paused_label.add_theme_font_size_override("font_size", 72)
	_paused_label.add_theme_color_override("font_color", UiStyle.CREAM)
	_paused_label.anchor_right = 1.0
	_paused_label.offset_top = 960.0
	_paused_label.offset_bottom = 1060.0
	_cover.add_child(_paused_label)
	RunCoordinator.cashout_ready.connect(_show_cashout)
	_inspect = InspectCard.new()
	add_child(_inspect)
	# Score readout above the table, below the end panel and focus cover (score-cascade spec).
	_hud = ScoreHud.new()
	add_child(_hud)
	move_child(_hud, _end_panel.get_index())
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
	# Draw order: the end panel dims everything built above, and the focus cover
	# stays on top of all of it.
	move_child(_intro, -1)
	move_child(_cashout, -1)
	move_child(_end_panel, -1)
	move_child(_inspect, -1)  # inspect opens over the end panel too
	move_child(_cover, -1)
	move_child(_pause_menu, -1)

	_update_round_labels()
	_hud.reset(_scoring_config.heat_max)  # idle HEAT: what a fast lock would earn
	UiStyle.pickable(_ante_label, _reopen_intro)
	_show_intro()
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
	_set_rect(_throw_label, 0.0, 0.0, 0.5, 0.0, 40.0, 120.0, 0.0, 206.0)
	_set_rect(_total_label, 0.5, 0.0, 1.0, 0.0, 0.0, 120.0, -40.0, 206.0)
	_set_rect(_status, 0.0, 0.0, 1.0, 0.0, 40.0, 270.0, -40.0, 360.0)
	_set_rect(_result, 0.0, 0.0, 1.0, 0.0, 40.0, 494.0, -40.0, 598.0)
	if _hud != null:
		var vs := get_viewport_rect().size
		_hud.stamp_center = Vector2(vs.x * 0.5, vs.y * (0.27 + 0.66) * 0.5)
	if _timer_track != null:
		_set_rect(_timer_track, 0.0, 0.0, 0.0, 0.0, 30.0, 600.0, 1050.0, 656.0)
	_set_rect(_timer_bar, 0.0, 0.0, 0.0, 0.0, 40.0, 610.0, 1040.0, 646.0)
	if _total_plaque != null:
		_set_rect(_total_plaque, 0.5, 0.0, 1.0, 0.0, 10.0, 118.0, -48.0, 206.0)
	_set_rect(_tray, 0.0, 0.27, 1.0, 0.66, 0.0, 0.0, 0.0, 0.0)
	if _charm_row != null:
		_set_rect(_charm_row, 0.0, 0.0, 1.0, 0.0, 40.0, 1610.0, -40.0, 1770.0)
	_set_rect(_throw_button, 0.5, 1.0, 0.5, 1.0, -260.0, -300.0, 260.0, -120.0)
	# SKIP (before the first throw on a Risk ante) and trinkets (during lock windows)
	# never show together, so they share the row above THROW.
	if _skip_button != null:
		_set_rect(_skip_button, 0.5, 0.0, 0.5, 0.0, -260.0, 1800.0, 260.0, 1930.0)
	if _cashout != null:
		_cashout.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		_set_rect(_cashout.get_node("CashoutCard"), 0.0, 0.0, 1.0, 0.0, 60.0, 560.0, -60.0, 1460.0)
		_set_rect(_cashout_title, 0.0, 0.0, 1.0, 0.0, 40.0, 420.0, -40.0, 640.0)
		_set_rect(_cashout_rows, 0.0, 0.0, 1.0, 0.0, 130.0, 700.0, -130.0, 1060.0)
		_set_rect(_cashout.get_node("GoldCaption"), 0.0, 0.0, 1.0, 0.0, 130.0, 1120.0, -130.0, 1170.0)
		_set_rect(_cashout_total, 0.0, 0.0, 1.0, 0.0, 130.0, 1170.0, -130.0, 1380.0)
		_set_rect(_cashout_continue, 0.5, 1.0, 0.5, 1.0, -280.0, -300.0, 280.0, -120.0)
	if _intro != null:
		_intro.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		_set_rect(_intro.get_node("IntroCard"), 0.0, 0.0, 1.0, 0.0, 60.0, 640.0, -60.0, 1360.0)
		_set_rect(_intro_title, 0.0, 0.0, 1.0, 0.0, 40.0, 520.0, -40.0, 720.0)
		_set_rect(_intro_target, 0.0, 0.0, 1.0, 0.0, 100.0, 760.0, -100.0, 920.0)
		_set_rect(_intro_reward, 0.0, 0.0, 1.0, 0.0, 120.0, 960.0, -120.0, 1040.0)
		_set_rect(_intro_rule, 0.0, 0.0, 1.0, 0.0, 120.0, 1070.0, -120.0, 1300.0)
		_set_rect(_intro_play, 0.5, 1.0, 0.5, 1.0, -260.0, -300.0, 260.0, -120.0)
	if _trinket_row != null:
		_set_rect(_trinket_row, 0.0, 0.0, 1.0, 0.0, 40.0, 1800.0, -40.0, 1930.0)
	if _skip_hint != null:
		_set_rect(_skip_hint, 0.0, 0.0, 1.0, 0.0, 40.0, 1820.0, -40.0, 1910.0)
	if _urgency_label != null:
		_set_rect(_urgency_label, 0.0, 0.0, 1.0, 0.0, 40.0, 548.0, -44.0, 600.0)
	if _pause_button != null:
		# Bottom-left corner beside THROW: in reach, but far from the dice.
		_set_rect(_pause_button, 0.0, 1.0, 0.0, 1.0, 40.0, -275.0, 170.0, -145.0)
	if _end_panel != null:
		_end_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		# End-of-run card (run-flow spec): stamped title, the final total counting up,
		# a compact summary, then the run's build.
		_set_rect(_end_card, 0.0, 0.0, 1.0, 0.0, 60.0, 480.0, -60.0, 1400.0)
		_set_rect(_end_title, 0.0, 0.0, 1.0, 0.0, 40.0, 330.0, -40.0, 560.0)
		_set_rect(_end_score_caption, 0.0, 0.0, 1.0, 0.0, 100.0, 560.0, -100.0, 610.0)
		_set_rect(_end_score, 0.0, 0.0, 1.0, 0.0, 100.0, 600.0, -100.0, 760.0)
		_set_rect(_end_summary, 0.0, 0.0, 1.0, 0.0, 100.0, 790.0, -100.0, 1010.0)
		_set_rect(_end_build_caption, 0.0, 0.0, 1.0, 0.0, 100.0, 1110.0, -100.0, 1160.0)
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
	if get_tree().paused or _end_panel.visible:
		return  # an abandoned or finished run never ticks on behind the end panel
	_controller.tick(delta)
	_update_visuals()


func _update_visuals() -> void:
	match _controller.state:
		ThrowController.State.TUMBLE, ThrowController.State.REROLL:
			_timer_bar.visible = false
			_trinket_row.visible = false
			_tumbler.tick(get_process_delta_time())
			_update_urgency(INF)
		ThrowController.State.LOCK_WINDOW:
			_timer_bar.visible = true
			_trinket_row.visible = true
			var left := _controller.time_remaining()
			_timer_bar.size.x = TIMER_BAR_FULL_WIDTH * left / _effective_window_s
			# Live Heat: what locking everything right now would score (heat spec).
			_hud.set_heat(Heat.from_remaining(_controller.projected_window_remaining(),
				_scoring_config, _effective_window_s))
			_update_urgency(left)
		_:
			pass


## Timer urgency (throw-loop spec): the last urgency_s pulses toward oxblood.
func _update_urgency(left: float) -> void:
	if left >= _fx.urgency_s:
		_timer_fill.modulate = Color.WHITE
		_timer_track.modulate = Color.WHITE
		if _urgency_label != null:
			_urgency_label.visible = false
		return
	var k := 1.0 - left / _fx.urgency_s
	# Calm pulse (≤ 2 Hz, flashing guideline) plus the seconds left as a number, so
	# urgency doesn't rely on colour alone.
	var pulse := 0.5 + 0.5 * sin(Time.get_ticks_msec() / 1000.0 * TAU * _fx.urgency_pulse_hz)
	_timer_fill.modulate = Color.WHITE.lerp(URGENT_TINT, k).lightened(0.3 * pulse)
	_timer_track.modulate = Color.WHITE.lerp(Color(1.4, 0.7, 0.6), k * pulse)
	_urgency_label.text = "%.1f" % left
	_urgency_label.visible = true


func _gui_input(event: InputEvent) -> void:
	if get_tree().paused or _focus_paused:
		return
	var mb := event as InputEventMouseButton
	if mb == null or not mb.pressed or mb.button_index != MOUSE_BUTTON_LEFT:
		return
	# Tap-to-skip (score-cascade spec): any tap off the buttons ends the build-up.
	if _cascade != null and _cascade.is_playing():
		if _cascade.elapsed_s() >= _fx.skip_grace_s:
			_cascade.skip()
		return
	# Use the event's own position (local to this Control) in the die rects' global
	# space; never the OS cursor. Touch arrives as emulated mouse events, and the
	# global transform also follows the screen-shake offset.
	_try_lock_at(get_global_transform() * mb.position)


## Tap forgiveness (throw-loop spec): the tap resolves to the nearest die of any
## state within tap_forgiveness_radius_px. An unlocked die locks; a locked or
## shattered die only wiggles "denied", so a tap aimed at a locked die can never
## forgive over to its neighbour (locks are irreversible).
func _try_lock_at(point: Vector2) -> void:
	if _tumbler == null:
		return
	var best := -1
	var best_dist := INF
	for i in _controller.faces.size():
		var rect := _tumbler.die_rect(i)
		var clamped := point.clamp(rect.position, rect.end)
		var dist := point.distance_to(clamped)
		if dist < best_dist:
			best_dist = dist
			best = i
	if best < 0 or best_dist > _config.tap_forgiveness_radius_px:
		return
	if _controller.locked[best] or _controller.is_shattered(best):
		_tumbler.deny_die(best)
		return
	_controller.lock_die(best)


func _on_throw_pressed() -> void:
	_intro.visible = false
	_result.text = ""
	_result.scale = Vector2.ONE  # reset in case previous cascade was interrupted
	_hud.clear_transients()
	_hud.reset(_scoring_config.heat_max)
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
		if t.icon != null:  # the same chip as on its shop card (add-shop-icons)
			btn.icon = t.icon
			btn.add_theme_constant_override("icon_max_width", 92)
			btn.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
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
	_brief = AnteBrief.for_ante(_arc.current_ante, _ante_config, RunCoordinator.shop_config, _config)
	var chip := " · " + _brief.short_rule if _brief.is_boss else ""
	_ante_label.text = "ANTE %d / %d%s%s" % [_arc.current_ante, _ante_config.targets.size(), round_name, chip]
	# The throw about to be made (or in progress): "Throw 1 of 3" before the first.
	_throw_label.text = "Throw %d of %d" % [mini(_round.current_throw + 1, _ante_config.throws_per_round),
		_ante_config.throws_per_round]
	_total_label.text = ScoreHud.total_text(_round.total, _round.target)
	if _hud != null:
		_hud.set_target_fraction(float(_round.total) / float(maxi(_round.target, 1)))


func _on_window_started(window_index: int) -> void:
	_tumbler.reveal(_controller.faces, _controller.locked)
	_refresh_lock_preview(false)


## Live locked-set preview (throw-loop spec): the best combo of the dice locked so
## far, scored read-only without charms; the plaques show the hand's base and the
## status band names it. Charms and the final total stay hidden for the cascade.
func _refresh_lock_preview(punch: bool) -> void:
	var window := "Window %d / 3" % _controller.window_index
	if not _controller.locked.has(true):
		_status.text = window + " — TAP TO LOCK"
		return
	var bd := _scoring.score(_controller.snapshot_result(), _scoring_config, _effective_window_s)
	var base := ScoreCascade.combo_base(bd, _scoring_config.base_mult)
	var names: Array[String] = []
	for c in bd.combos:
		names.append(String(c.name).to_upper())
	if names.is_empty():
		_status.text = window + " · no combo yet"
	else:
		_status.text = "%s · %s · %d × %d" % [window, " + ".join(names), base.chips, base.mult]
	var changed := _hud.chips_label.text != str(base.chips) or _hud.mult_label.text != ScoreHud.fmt_mult(base.mult)
	_hud.set_chips(base.chips)
	_hud.set_mult(base.mult)
	if punch and changed:
		_hud.punch(_hud.chips_label)
		_hud.punch(_hud.mult_label)


func _on_die_locked(die_index: int, _window_index: int) -> void:
	_tumbler.lock_die(die_index, _controller.faces[die_index])
	if _controller.state == ThrowController.State.LOCK_WINDOW:
		_refresh_lock_preview(true)
	# Lock feedback (throw-loop spec): the die punches and the table nudges.
	_tumbler.punch_die(die_index, _fx.lock_punch_scale, _fx.lock_punch_s)
	_nudge_tray(_fx.lock_shake_px, _fx.lock_shake_s)
	if Settings.haptics:
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
			if not _tumbler.dead[i]:  # newly shattered: say so once (add-lock-signifiers)
				var r := _tumbler.die_rect(i)
				if r.size != Vector2.ZERO:
					_hud.float_text("SHATTERED", r.get_center(), UiStyle.CREAM, 30)
			_tumbler.mark_dead(i)


func _on_carve_activated(_die_index: int, carve_type: StringName) -> void:
	if carve_type == &"spark":
		_controller.freeze_window(0.5)


## Lock feedback moves only the tray, so the HUD text stays still while you read it;
## full-screen shake is kept for combos and TARGET HIT.
func _nudge_tray(amplitude: float, duration: float) -> void:
	amplitude *= Settings.shake_scale()
	if amplitude <= 0.0 or duration <= 0.0:
		return
	if _tray_tween != null and _tray_tween.is_valid():
		_tray_tween.kill()
		_set_rect(_tray, 0.0, 0.27, 1.0, 0.66, 0.0, 0.0, 0.0, 0.0)
	var home := _tray.position
	_tray_tween = create_tween()
	for dx: float in [amplitude, -amplitude * 0.6, 0.0]:
		_tray_tween.tween_property(_tray, "position:x", home.x + dx, duration / 3.0)


func _screen_shake(amplitude: float, duration: float) -> void:
	amplitude *= Settings.shake_scale()
	if amplitude <= 0.0 or duration <= 0.0:
		return
	if _shake_tween != null and _shake_tween.is_valid():
		_shake_tween.kill()
	var tween := create_tween()
	_shake_tween = tween
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
	_update_urgency(INF)
	_status.text = ""  # the score build-up owns this band until it lands
	_mark_dead_slots()
	_tumbler.reveal(_controller.faces, _controller.locked)
	var breakdown := _scoring.score(result, _scoring_config, _effective_window_s, false, RunCoordinator.inventory)
	if not breakdown.combos.is_empty() and _sfx_combo != null and _sfx_combo.stream != null:
		_sfx_combo.play()
	var old_total := _round.total
	var new_total := old_total + breakdown.final_score
	_cascade = ScoreCascade.new(self, _tumbler, _hud, _result, _total_label, _scoring_config, _fx)
	_cascade.shake_requested.connect(_screen_shake)
	_cascade.finished.connect(_on_cascade_finished)
	_skip_hint.visible = true
	_cascade.charm_triggered.connect(_pulse_charm)
	_cascade.play(breakdown, old_total, new_total, _round.target)
	_apply_score_speed()


## Score speed setting: 2× plays the cascade faster; Instant jumps to its end.
func _apply_score_speed() -> void:
	if _cascade == null or not _cascade.is_playing():
		return
	if Settings.cascade_speed == 0.0:
		_cascade.skip()
	else:
		_cascade.set_speed(Settings.cascade_speed)


func _on_cascade_finished() -> void:
	_skip_hint.visible = false
	if _end_panel.visible:
		return
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


## Round-cleared panel (run-flow spec): the gold earned, line by line, then the new
## total stamps in; CONTINUE goes to the shop. Same card language as the end panel.
func _build_cashout() -> void:
	_cashout = ColorRect.new()
	_cashout.color = Color(0.02, 0.01, 0.01, 0.82)
	_cashout.visible = false
	add_child(_cashout)
	var card := Panel.new()
	card.name = "CashoutCard"
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_cashout.add_child(card)
	_cashout_title = Label.new()
	ScoreHud.style_stamp(_cashout_title, 104)
	_cashout.add_child(_cashout_title)
	_cashout_rows = VBoxContainer.new()
	_cashout_rows.add_theme_constant_override("separation", 18)
	_cashout_rows.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_cashout.add_child(_cashout_rows)
	var caption := Label.new()
	caption.name = "GoldCaption"
	caption.text = "GOLD"
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption.add_theme_font_size_override("font_size", 30)
	caption.add_theme_color_override("font_color", UiStyle.MUTED)
	_cashout.add_child(caption)
	_cashout_total = Label.new()
	_cashout_total.theme_type_variation = &"HudValue"
	_cashout_total.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_cashout_total.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_cashout_total.add_theme_font_size_override("font_size", 120)
	_cashout_total.add_theme_color_override("font_outline_color", UiStyle.OUTLINE)
	_cashout_total.add_theme_constant_override("outline_size", 14)
	_cashout.add_child(_cashout_total)
	_cashout_continue = Button.new()
	_cashout_continue.text = "CONTINUE"
	_cashout_continue.theme_type_variation = &"ThrowButton"
	_cashout_continue.pressed.connect(RunCoordinator.go_to_shop)
	_cashout.add_child(_cashout_continue)


func _show_cashout(data: Dictionary) -> void:
	if not is_inside_tree():
		return
	_intro.visible = false
	_throw_button.visible = false
	_cashout_title.text = data.title
	_cashout_title.rotation = ScoreHud.STAMP_ANGLE
	for c in _cashout_rows.get_children():
		c.queue_free()
	var rows: Array[Control] = []
	for line in data.lines:
		var row := HBoxContainer.new()
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var text := Label.new()
		text.text = line.text
		text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		text.add_theme_font_size_override("font_size", 40)
		row.add_child(text)
		var value := Label.new()
		value.text = "%+dg" % int(line.gold)
		value.theme_type_variation = &"HudValue"
		value.add_theme_font_size_override("font_size", 44)
		row.add_child(value)
		row.modulate.a = 0.0
		_cashout_rows.add_child(row)
		rows.append(row)
	_cashout_total.text = str(int(data.before))
	_cashout.visible = true
	await get_tree().process_frame
	if not is_inside_tree() or not _cashout.visible:
		return
	ScoreHud.slam(_cashout_title, 2.2)
	var t := create_tween()
	t.tween_interval(0.35)
	for row in rows:
		t.tween_property(row, "modulate:a", 1.0, 0.12)
		t.parallel().tween_callback(_hud.punch.bind(row, 1.08, 0.2))
		t.tween_interval(0.28)
	t.tween_method(func(v: float) -> void: _cashout_total.text = str(roundi(v)),
		float(data.before), float(data.after), 0.5)
	t.tween_callback(func() -> void: _hud.punch(_cashout_total, 1.35, 0.3))


## Ante intro card (ante-arc / throw-loop spec): the ante's target, reward and rule in
## plain words before the first throw; PLAY sits exactly where THROW is.
func _build_intro() -> void:
	_intro = ColorRect.new()
	_intro.color = Color(0.02, 0.01, 0.01, 0.78)
	_intro.visible = false
	add_child(_intro)
	var card := Panel.new()
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.name = "IntroCard"
	_intro.add_child(card)
	_intro_title = _intro_label(52, UiStyle.AMBER)
	ScoreHud.style_stamp(_intro_title, 60)
	_intro_target = _intro_label(96, UiStyle.CREAM)
	_intro_target.add_theme_color_override("font_outline_color", UiStyle.OUTLINE)
	_intro_target.add_theme_constant_override("outline_size", 12)
	_intro_reward = _intro_label(40, UiStyle.CREAM.darkened(0.08))
	_intro_rule = _intro_label(40, UiStyle.AMBER)
	_intro_rule.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_intro_play = Button.new()
	_intro_play.text = "PLAY"
	_intro_play.theme_type_variation = &"ThrowButton"
	_intro_play.pressed.connect(func() -> void: _intro.visible = false)
	_intro.add_child(_intro_play)


func _intro_label(font_size: int, color: Color) -> Label:
	var l := Label.new()
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_intro.add_child(l)
	return l


func _show_intro() -> void:
	if _round.current_throw > 0 or _round.is_done:
		return
	_fill_intro()
	_skip_button.visible = _brief.is_risk
	_intro.visible = true
	get_tree().process_frame.connect(_slam_intro_title, CONNECT_ONE_SHOT)


func _slam_intro_title() -> void:
	ScoreHud.slam(_intro_title, 1.8)


## Tapping the ante label re-reads the brief between throws (never while the clock
## runs); SKIP only appears before the first throw.
func _reopen_intro() -> void:
	var s := _controller.state
	if s == ThrowController.State.TUMBLE or s == ThrowController.State.LOCK_WINDOW \
			or s == ThrowController.State.REROLL or (_cascade != null and _cascade.is_playing()):
		return
	if _end_panel.visible:
		return
	_fill_intro()
	_skip_button.visible = _brief.is_risk and _round.current_throw == 0
	_intro.visible = true


func _fill_intro() -> void:
	_intro_title.text = _brief.title
	_intro_target.text = "TARGET %d" % _brief.target
	_intro_reward.text = _brief.reward
	_intro_rule.text = _brief.rule


## End-of-run panel (run-flow spec): result, summary, NEW RUN / MENU. Sits above the
## tray and below the focus cover, so focus loss still covers everything.
func _build_end_panel() -> void:
	_end_panel = ColorRect.new()
	_end_panel.color = Color(0.02, 0.01, 0.01, 0.86)
	_end_panel.visible = false
	add_child(_end_panel)
	move_child(_end_panel, _cover.get_index())
	_end_card = Panel.new()
	_end_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_end_panel.add_child(_end_card)
	_end_title = _end_label(124)
	ScoreHud.style_stamp(_end_title, 124)
	_end_score_caption = _end_label(30)
	_end_score_caption.add_theme_color_override("font_color", UiStyle.MUTED)
	_end_score = _end_label(130)
	_end_score.theme_type_variation = &"HudValue"
	_end_score.add_theme_color_override("font_outline_color", UiStyle.OUTLINE)
	_end_score.add_theme_constant_override("outline_size", 14)
	_end_summary = _end_label(42)
	_end_summary.add_theme_constant_override("line_spacing", 10)
	_end_build_caption = _end_label(30)
	_end_build_caption.add_theme_color_override("font_color", UiStyle.MUTED)
	_end_build_caption.text = "YOUR BUILD"
	_new_run_button = _end_button("NEW RUN")
	_new_run_button.theme_type_variation = &"ThrowButton"
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
		slot.expand_icon = true
		slot.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		slot.vertical_icon_alignment = VERTICAL_ALIGNMENT_CENTER
		if i < charms.size():
			var charm: CharmEffect = charms[i]
			# Medallion over the socket; the name and rule show on tap (add-charm-icons).
			slot.icon = charm.icon
			slot.text = "" if charm.icon != null else charm.display_name
			slot.tooltip_text = charm.display_name
			slot.pressed.connect(func() -> void: _inspect.show_item(charm, INSPECT_ABOVE_SLOTS_Y))
		else:
			slot.text = ""  # an empty, dimmed socket says "free slot" on its own
			slot.disabled = true
		_charm_row.add_child(slot)
		_charm_slots.append(slot)


## Trigger pulse (add-charm-icons): the slot of a charm that changed the score pops
## and flares, so the player sees which part of the build fired.
func _pulse_charm(slot_index: int) -> Tween:
	if slot_index < 0 or slot_index >= _charm_slots.size():
		return null
	var slot := _charm_slots[slot_index]
	slot.pivot_offset = slot.size / 2.0
	var t := create_tween()
	t.tween_property(slot, "scale", Vector2.ONE * 1.28, 0.08).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.parallel().tween_property(slot, "modulate", Color(1.6, 1.35, 0.9), 0.08)
	t.tween_property(slot, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	t.parallel().tween_property(slot, "modulate", Color.WHITE, 0.3)
	return t


func _show_end_panel(won: bool) -> void:
	# The run's build as medallions under the summary.
	if _end_build != null:
		_end_build.queue_free()
	_end_build = UiStyle.charm_row(RunCoordinator.inventory.iter_charms(), CHARM_SLOTS, 132.0,
		func(c: CharmEffect) -> void: _inspect.show_item(c, INSPECT_ABOVE_BUILD_Y))
	_end_panel.add_child(_end_build)
	_set_rect(_end_build, 0.0, 0.0, 1.0, 0.0, 100.0, 1170.0, -100.0, 1320.0)
	_end_title.text = "RUN WON" if won else "GAME OVER"
	_end_title.add_theme_color_override("font_color", UiStyle.AMBER if won else UiStyle.CREAM)
	_end_score_caption.text = "FINAL TOTAL  /  TARGET %d" % _round.target
	_end_summary.text = "Ante %d / %d   ·   Best throw %d\nSeed %d" % [
		_arc.current_ante, _ante_config.targets.size(), RunCoordinator.best_throw, RngService.run_seed]
	_skip_button.visible = false
	_throw_button.visible = false  # NEW RUN / MENU are the only actions now
	_end_panel.visible = true
	_play_end_reveal(won)


## The end-of-run reveal: the title slams in (win: heavy shake and sparks; loss: a
## thud), then the final total counts up and lands with a punch.
func _play_end_reveal(won: bool) -> void:
	_end_score.text = "0"
	_end_title.rotation = ScoreHud.STAMP_ANGLE
	await get_tree().process_frame  # labels have their laid-out size now
	if not is_inside_tree() or not _end_panel.visible:
		return
	ScoreHud.slam(_end_title)
	var tier := 4 if won else 2
	_screen_shake(_fx.shake_px_by_tier[tier], _fx.shake_s_by_tier[tier])
	if won:
		ScoreHud.spawn_burst(_end_panel, _end_title.get_global_rect().get_center(), _fx.sparks_by_tier[5])
	var t := create_tween()
	t.tween_interval(0.35)
	t.tween_method(func(v: float) -> void: _end_score.text = str(roundi(v)),
		0.0, float(_round.total), _fx.tick_s(_round.total, _scoring_config.cascade_duration_s))
	t.tween_callback(func() -> void: _hud.punch(_end_score, 1.3, 0.3))


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


## Manual pause (throw-loop spec): the focus-loss pause plus the pause menu.
func open_pause() -> void:
	if _end_panel.visible or _cashout.visible or _menu_open:
		return
	_menu_open = true
	_on_focus_lost()
	_pause_menu.open_main()


func _on_pause_resume() -> void:
	_menu_open = false
	_paused_label.visible = true
	var s := _controller.state
	if s == ThrowController.State.TUMBLE or s == ThrowController.State.LOCK_WINDOW \
			or s == ThrowController.State.REROLL:
		_on_focus_returned()  # 3-2-1 and the window restarts, as after focus loss
		return
	_focus_paused = false
	get_tree().paused = false
	_cover.visible = false


## Abandon run (run-flow spec): ends the run now as a loss, through the end panel.
func _on_abandon() -> void:
	_menu_open = false
	_focus_paused = false
	get_tree().paused = false
	_cover.visible = false
	if _cascade != null and _cascade.is_playing():
		_cascade.skip()
	if not _end_panel.visible:
		_arc.on_round_lost()


func _on_focus_lost() -> void:
	if _focus_paused or not is_inside_tree():
		return
	_focus_paused = true
	_countdown_left = -1.0
	get_tree().paused = true
	_cover.visible = true
	_paused_label.visible = not _menu_open  # the menu carries its own title
	_countdown_label.text = ""


func _on_focus_returned() -> void:
	if not _focus_paused or _menu_open:
		return  # the pause menu stays up until the player resumes
	_focus_paused = false
	_countdown_left = _config.resume_countdown_s
