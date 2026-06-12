extends GutTest
## Determinism tests for RngCore (seeded-rng spec scenarios).


func test_same_seed_same_sequence() -> void:
	var a := RngCore.new(12345)
	var b := RngCore.new(12345)
	for i in 100:
		assert_eq(
			a.randi_range(RngCore.STREAM_DICE, 1, 6),
			b.randi_range(RngCore.STREAM_DICE, 1, 6),
			"draw %d diverged for identical seeds" % i
		)


func test_different_seeds_diverge() -> void:
	var a := RngCore.new(12345)
	var b := RngCore.new(54321)
	var a_faces: Array[int] = []
	var b_faces: Array[int] = []
	for i in 20:
		a_faces.append(a.randi_range(RngCore.STREAM_DICE, 1, 6))
		b_faces.append(b.randi_range(RngCore.STREAM_DICE, 1, 6))
	assert_ne(a_faces, b_faces, "different seeds produced the same 20-face sequence")


func test_stream_independence() -> void:
	# Shop draws between dice draws must not shift the dice stream.
	var clean := RngCore.new(777)
	var noisy := RngCore.new(777)
	var clean_faces: Array[int] = []
	var noisy_faces: Array[int] = []
	for i in 50:
		clean_faces.append(clean.randi_range(RngCore.STREAM_DICE, 1, 6))
		noisy.randi_range(RngCore.STREAM_SHOP, 0, 100)
		noisy.randf(RngCore.STREAM_SHOP)
		noisy_faces.append(noisy.randi_range(RngCore.STREAM_DICE, 1, 6))
	assert_eq(noisy_faces, clean_faces, "shop draws shifted the dice stream")


func test_generated_seed_reproduces_run() -> void:
	var original := RngCore.new()
	assert_ne(original.run_seed, 0, "generated seed must be retrievable and non-zero")
	var faces: Array[int] = []
	for i in 30:
		faces.append(original.randi_range(RngCore.STREAM_DICE, 1, 6))
	var replay := RngCore.new(original.run_seed)
	var replay_faces: Array[int] = []
	for i in 30:
		replay_faces.append(replay.randi_range(RngCore.STREAM_DICE, 1, 6))
	assert_eq(replay_faces, faces, "logged seed did not reproduce the run")


func test_shuffle_is_deterministic_and_complete() -> void:
	var a_items := range(20)
	var b_items := range(20)
	RngCore.new(99).shuffle(RngCore.STREAM_BAG, a_items)
	RngCore.new(99).shuffle(RngCore.STREAM_BAG, b_items)
	assert_eq(a_items, b_items, "same seed gave different shuffles")
	var sorted_items := a_items.duplicate()
	sorted_items.sort()
	assert_eq(sorted_items, range(20), "shuffle lost or duplicated elements")
