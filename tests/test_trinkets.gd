extends GutTest
## Headless tests for TrinketInventory, freeze_window, and force_reroll_unlocked.

const _WINDOW_S := 1.0

var _config: ThrowConfig
var _bag: DiceBag
var _controller: ThrowController


func _make_controller() -> void:
	_config = ThrowConfig.new()
	_config.lock_window_duration_s = _WINDOW_S
	_bag = DiceBag.new(_config.starting_bag_size)
	_controller = ThrowController.new(_config, _bag, RngCore.new(77))


func _tick_for(seconds: float) -> void:
	var dt := 1.0 / 60.0
	var steps := int(ceil(seconds * 60.0))
	for _i in steps:
		_controller.tick(dt)


func _tick_until_window(window: int) -> void:
	var dt := 1.0 / 60.0
	for _i in 10000:
		if _controller.state == ThrowController.State.LOCK_WINDOW \
				and _controller.window_index == window:
			return
		_controller.tick(dt)
	fail_test("window %d never started" % window)


# --- TrinketInventory --------------------------------------------------------

func test_inventory_accepts_up_to_max_slots() -> void:
	var inv := TrinketInventory.new()
	assert_true(inv.add_trinket(Trinket.new()), "first slot accepted")
	assert_true(inv.add_trinket(Trinket.new()), "second slot accepted")
	assert_true(inv.is_full())


func test_inventory_rejects_third_trinket() -> void:
	var inv := TrinketInventory.new()
	var accepted := 0
	for _i in 3:
		if inv.add_trinket(Trinket.new()):
			accepted += 1
	assert_eq(accepted, 2, "only two trinkets accepted (MAX_SLOTS = 2)")


func test_consume_removes_trinket_and_frees_slot() -> void:
	var inv := TrinketInventory.new()
	var t := Trinket.new()
	t.display_name = "Sentinel"
	inv.add_trinket(t)
	var consumed: Trinket = inv.consume(0)
	assert_not_null(consumed)
	assert_eq(consumed.display_name, "Sentinel")
	assert_false(inv.is_full(), "slot freed after consume")


func test_consume_out_of_range_returns_null() -> void:
	var inv := TrinketInventory.new()
	assert_null(inv.consume(0))
	assert_null(inv.consume(-1))


# --- freeze_window -----------------------------------------------------------

func test_freeze_window_extends_current_window() -> void:
	_make_controller()
	_controller.start_throw()
	_tick_until_window(1)
	_tick_for(0.6)  # 0.6s of 1.0s window elapsed; 0.4s remaining
	assert_eq(_controller.state, ThrowController.State.LOCK_WINDOW)
	_controller.freeze_window(2.0)  # rewinds _accumulated: max(0, 0.6 - 2.0) = 0
	_tick_for(0.8)  # after freeze, 0.8s elapsed of a fresh 1.0s window
	assert_eq(_controller.state, ThrowController.State.LOCK_WINDOW,
			"window still open after freeze then 0.8 s (would have expired without freeze)")


func test_freeze_window_no_op_outside_window() -> void:
	_make_controller()
	_controller.start_throw()
	assert_eq(_controller.state, ThrowController.State.TUMBLE)
	_controller.freeze_window(5.0)
	assert_eq(_controller.state, ThrowController.State.TUMBLE,
			"freeze is a no-op outside LOCK_WINDOW")


func test_freeze_window_clamps_to_zero() -> void:
	_make_controller()
	_controller.start_throw()
	_tick_until_window(1)
	_tick_for(0.3)
	_controller.freeze_window(99.0)  # would go negative — must clamp
	assert_eq(_controller.time_remaining(), _WINDOW_S,
			"remaining resets to full window duration after large freeze")


# --- force_reroll_unlocked ---------------------------------------------------

func test_force_reroll_fires_reroll_signal() -> void:
	_make_controller()
	_controller.start_throw()
	_tick_until_window(1)
	var rerolled: Array[int] = []
	_controller.reroll_started.connect(func(arr: Array[int]) -> void: rerolled.append_array(arr))
	_controller.force_reroll_unlocked()
	assert_gt(rerolled.size(), 0, "at least one die re-rolled")
	assert_eq(_controller.state, ThrowController.State.LOCK_WINDOW,
			"still in LOCK_WINDOW after force-reroll")


func test_force_reroll_no_op_outside_window() -> void:
	_make_controller()
	_controller.start_throw()
	assert_eq(_controller.state, ThrowController.State.TUMBLE)
	var fired := false
	_controller.reroll_started.connect(func(_a: Array[int]) -> void: fired = true)
	_controller.force_reroll_unlocked()
	assert_false(fired, "reroll_started must not fire outside LOCK_WINDOW")
