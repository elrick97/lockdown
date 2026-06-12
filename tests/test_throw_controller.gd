extends GutTest
## throw-loop spec scenarios, driven entirely through tick()/lock_die().

var _config: ThrowConfig
var _bag: DiceBag
var _controller: ThrowController
var _result: ThrowResult
var _windows_seen: Array[int]
var _rerolls_seen: Array
var _locks_seen: Array


func before_each() -> void:
	_config = ThrowConfig.new()
	_bag = DiceBag.new(_config.starting_bag_size)
	_controller = ThrowController.new(_config, _bag, RngCore.new(123))
	_result = null
	_windows_seen = []
	_rerolls_seen = []
	_locks_seen = []
	_controller.window_started.connect(func(w: int) -> void: _windows_seen.append(w))
	_controller.reroll_started.connect(func(idx: Array[int]) -> void: _rerolls_seen.append(idx.duplicate()))
	_controller.die_locked.connect(func(d: int, w: int) -> void: _locks_seen.append([d, w]))
	_controller.resolved.connect(func(r: ThrowResult) -> void: _result = r)


func _tick_for(seconds: float, fps: int = 60) -> void:
	var dt := 1.0 / fps
	var steps := int(ceil(seconds * fps))
	for i in steps:
		_controller.tick(dt)


func _tick_until_window(window: int) -> void:
	var dt := 1.0 / 60.0
	for i in 10000:
		if _controller.state == ThrowController.State.LOCK_WINDOW and _controller.window_index == window:
			return
		_controller.tick(dt)
	fail_test("window %d never started" % window)


func test_full_three_window_sequence() -> void:
	_controller.start_throw()
	assert_eq(_controller.state, ThrowController.State.TUMBLE)
	assert_eq(_controller.faces.size(), 6, "draw_size dice on the tray")
	_tick_for(20.0)
	assert_eq(_controller.state, ThrowController.State.RESOLVED)
	assert_eq(_windows_seen, [1, 2, 3], "all three windows in order")
	assert_eq(_rerolls_seen.size(), 2, "re-roll after windows 1 and 2 only")
	assert_not_null(_result)
	assert_eq(_result.window_remaining_s, [0.0, 0.0, 0.0], "expired windows report zero remaining")


func test_force_lock_locks_everything() -> void:
	_controller.start_throw()
	_tick_for(20.0)
	assert_eq(_result.locked_order.size(), 6, "all dice locked by force-lock")
	assert_false(_controller.locked.has(false))
	for lock in _locks_seen:
		assert_eq(lock[1], 3, "force-locks attributed to window 3")


func test_partial_lock_rerolls_only_unlocked() -> void:
	_controller.start_throw()
	_tick_until_window(1)
	var face0: int = _controller.faces[0]
	var face1: int = _controller.faces[1]
	assert_true(_controller.lock_die(0))
	assert_true(_controller.lock_die(1))
	_tick_for(3.0)  # expire window 1
	assert_eq(_rerolls_seen[0], [2, 3, 4, 5], "only unlocked dice re-roll")
	assert_eq(_controller.faces[0], face0, "locked die kept its face")
	assert_eq(_controller.faces[1], face1, "locked die kept its face")


func test_locks_are_irreversible_and_window_only() -> void:
	_controller.start_throw()
	assert_false(_controller.lock_die(0), "no locking during tumble")
	_tick_until_window(1)
	assert_true(_controller.lock_die(0))
	assert_false(_controller.lock_die(0), "second tap on a locked die does nothing")
	assert_false(_controller.lock_die(-1))
	assert_false(_controller.lock_die(99))


func test_early_resolution_credits_unstarted_windows() -> void:
	_controller.start_throw()
	_tick_until_window(1)
	_tick_for(0.5)
	for i in 6:
		_controller.lock_die(i)
	assert_eq(_controller.state, ThrowController.State.RESOLVED, "all locked resolves immediately")
	assert_almost_eq(_result.window_remaining_s[0], 2.0, 0.05, "window 1 remaining ~2.0s")
	assert_eq(_result.window_remaining_s[1], 2.5, "skipped window 2 credited in full")
	assert_eq(_result.window_remaining_s[2], 2.5, "skipped window 3 credited in full")
	assert_eq(_windows_seen, [1], "windows 2 and 3 never started")


func test_window_duration_is_frame_rate_independent() -> void:
	var secs_30 := _window_seconds_at_fps(30)
	var secs_60 := _window_seconds_at_fps(60)
	assert_almost_eq(secs_30, secs_60, 1.0 / 30.0 + 0.001,
		"30 fps and 60 fps windows must drain in equal wall time")
	assert_almost_eq(secs_60, _config.lock_window_duration_s, 1.0 / 30.0 + 0.001)


func _window_seconds_at_fps(fps: int) -> float:
	var c := ThrowController.new(_config, DiceBag.new(8), RngCore.new(7))
	c.start_throw()
	var dt := 1.0 / fps
	while c.state != ThrowController.State.LOCK_WINDOW:
		c.tick(dt)
	var elapsed := 0.0
	while c.state == ThrowController.State.LOCK_WINDOW:
		c.tick(dt)
		elapsed += dt
	return elapsed


func test_restart_window_keeps_locks_and_refills_timer() -> void:
	_controller.start_throw()
	_tick_until_window(1)
	_controller.lock_die(2)
	_tick_for(1.0)
	assert_almost_eq(_controller.time_remaining(), 1.5, 0.05)
	_controller.restart_window()
	assert_almost_eq(_controller.time_remaining(), 2.5, 0.001, "full timer after restart")
	assert_true(_controller.locked[2], "locks survive the restart")
	assert_eq(_controller.window_index, 1, "still the same window")


func test_scripted_throw_is_deterministic() -> void:
	var a := _scripted_run(987)
	var b := _scripted_run(987)
	assert_eq(a.faces, b.faces, "same seed + same inputs → same faces")
	assert_eq(a.locked_order, b.locked_order)
	assert_eq(a.window_remaining_s, b.window_remaining_s)
	var c := _scripted_run(988)
	assert_ne(a.faces, c.faces, "different seed should diverge")


func _scripted_run(seed_value: int) -> ThrowResult:
	var cfg := ThrowConfig.new()
	var controller := ThrowController.new(cfg, DiceBag.new(cfg.starting_bag_size), RngCore.new(seed_value))
	controller.start_throw()
	var dt := 1.0 / 60.0
	for i in 2000:
		if controller.state == ThrowController.State.RESOLVED:
			break
		controller.tick(dt)
		if i == 120:
			controller.lock_die(0)
		if i == 140:
			controller.lock_die(3)
		if i == 400:
			controller.lock_die(1)
	assert_not_null(controller.last_result, "scripted run must resolve")
	return controller.last_result
