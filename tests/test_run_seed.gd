extends GutTest
## seeded-rng spec, Deterministic reproduction: a run is seeded once, when it
## starts. Re-entering the throw scene (every ante, after the shop) must keep the
## same seed and continue the same random streams, not reseed.

const SCENE := preload("res://scenes/throw/throw_scene.tscn")
const SEED := 424242


func _enter_throw_scene() -> Control:
	var scene: Control = SCENE.instantiate()
	add_child_autofree(scene)
	scene.ante_cleared.disconnect(RunCoordinator.on_ante_cleared)
	return scene


## Faces as a run would roll them: some in ante 1, then the throw scene is
## re-entered (as after the shop) and more are rolled in ante 2.
func _faces_across_two_antes() -> Array[int]:
	RunCoordinator.start_run(SEED)
	var faces: Array[int] = []
	var first := _enter_throw_scene()
	for i in 5:
		faces.append(RngService.randi_range(RngCore.STREAM_DICE, 1, 6))
	first.free()
	_enter_throw_scene()
	for i in 5:
		faces.append(RngService.randi_range(RngCore.STREAM_DICE, 1, 6))
	return faces


func test_start_run_seeds_the_rng() -> void:
	RunCoordinator.start_run(SEED)
	assert_eq(RngService.run_seed, SEED, "the run's explicit seed reaches RngService")


func test_entering_the_throw_scene_keeps_the_seed() -> void:
	RunCoordinator.start_run(SEED)
	var core := RngService.get_core()
	_enter_throw_scene()
	assert_eq(RngService.run_seed, SEED, "throw scene does not reseed")
	assert_same(RngService.get_core(), core, "throw scene keeps the run's RNG streams")


func test_same_seed_same_faces_across_antes() -> void:
	var a := _faces_across_two_antes()
	var b := _faces_across_two_antes()
	assert_eq(a, b, "same seed reproduces the faces of ante 1 and ante 2")
