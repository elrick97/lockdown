extends GutTest
## add-scene-transitions: the smoke wipe covers, blocks input, then reveals; reduced
## motion uses a plain fade.


func after_each() -> void:
	Settings.persist = false
	Settings.reset_defaults()
	Settings.persist = true
	SceneFader.rect.visible = false
	SceneFader.rect.mouse_filter = Control.MOUSE_FILTER_IGNORE


func test_cover_blocks_input_and_reveal_releases_it() -> void:
	assert_eq(SceneFader.layer, 100, "above the overlay and every screen")
	var t := SceneFader.cover()
	assert_true(SceneFader.rect.visible)
	assert_eq(SceneFader.rect.mouse_filter, Control.MOUSE_FILTER_STOP, "nothing tappable mid-wipe")
	await t.finished
	assert_almost_eq(SceneFader.progress(), 1.0, 0.001, "fully covered")
	await SceneFader.reveal().finished
	assert_almost_eq(SceneFader.progress(), 0.0, 0.001)
	assert_false(SceneFader.rect.visible)
	assert_eq(SceneFader.rect.mouse_filter, Control.MOUSE_FILTER_IGNORE)


func test_wipe_uses_the_fog_noise_and_plain_fade_for_reduced_motion() -> void:
	var mat := SceneFader.rect.material as ShaderMaterial
	assert_same(mat.get_shader_parameter("noise_tex"), SmokeOverlay.noise_texture())
	Settings.persist = false
	Settings.reduced_motion = true
	var t := SceneFader.cover()
	assert_true(mat.get_shader_parameter("plain"), "reduced motion: plain fade")
	await t.finished
	await SceneFader.reveal().finished


func test_wipe_is_short() -> void:
	assert_lte(SceneFader.TRANSITION_S, 0.3, "each half stays snappy")
