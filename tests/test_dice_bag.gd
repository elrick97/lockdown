extends GutTest
## dice-bag spec scenarios.


func test_standard_draw() -> void:
	var bag := DiceBag.new(8)
	var drawn := bag.draw(6, RngCore.new(1))
	assert_eq(drawn.size(), 6, "draw_size dice should leave the bag")
	assert_eq(bag.available(), 2)


func test_draw_clamped_to_tray_cap() -> void:
	var bag := DiceBag.new(12)
	var drawn := bag.draw(12, RngCore.new(1))
	assert_eq(drawn.size(), DiceBag.TRAY_CAP, "tray hard cap is 8")


func test_short_bag_draws_all_remaining() -> void:
	var bag := DiceBag.new(4)
	var drawn := bag.draw(6, RngCore.new(1))
	assert_eq(drawn.size(), 4)
	assert_eq(bag.available(), 0)


func test_dice_return_on_resolve() -> void:
	var bag := DiceBag.new(8)
	var drawn := bag.draw(6, RngCore.new(1))
	bag.return_dice(drawn)
	assert_eq(bag.available(), 8)


func test_draw_consumes_only_bag_stream() -> void:
	# A bag draw must not shift the dice stream (stream independence).
	var clean := RngCore.new(42)
	var used := RngCore.new(42)
	DiceBag.new(8).draw(6, used)
	for i in 20:
		assert_eq(
			used.randi_range(RngCore.STREAM_DICE, 1, 6),
			clean.randi_range(RngCore.STREAM_DICE, 1, 6),
			"bag draw shifted the dice stream at draw %d" % i
		)
