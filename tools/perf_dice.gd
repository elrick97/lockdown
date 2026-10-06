extends SceneTree
## Desktop frame-time stand-in for the dice renderer (add-smoke-room-dice, design D8;
## owner-approved: local only, no phone). Runs the real throw scene at its internal
## 1080×2400 with a full 8-die tray re-tumbling continuously, vsync off, and reports
## average / 95th-percentile / worst frame time to build/perf_dice.md.
##   godot_console --path . --rendering-driver opengl3 -s tools/perf_dice.gd

const THROW_SCENE := "res://scenes/throw/throw_scene.tscn"
const SECONDS := 20.0
const TUMBLE_S := 2.1  # Iron's slow tumble: the longest the dice keep moving
const MATERIALS: Array[StringName] = [&"standard", &"iron", &"glass", &"standard",
	&"glass", &"iron", &"standard", &"glass"]


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = 0
	root.get_node("RunCoordinator").start_run(4242)
	change_scene_to_file(THROW_SCENE)
	await process_frame
	await process_frame
	var tumbler: DiceTumbler = current_scene._tumbler
	var dice: Array[DiceBag.Die] = []
	for i in MATERIALS.size():
		# One carved die so the stamped-atlas path is in the measurement too.
		dice.append(DiceBag.Die.new(MATERIALS[i], 6, &"wild") if i == 0 else DiceBag.Die.new(MATERIALS[i]))
	tumbler.build(dice)
	var faces: Array[int] = []
	var locked: Array[bool] = []
	for i in dice.size():
		faces.append(1 + i % 6)
		locked.append(false)
	for i in 30:  # warm-up: shader compiles, texture uploads
		await process_frame
	var frame_ms: Array[float] = []
	var start := Time.get_ticks_usec()
	var last := start
	var next_tumble := start
	while Time.get_ticks_usec() - start < SECONDS * 1_000_000.0:
		var now := Time.get_ticks_usec()
		if now >= next_tumble:
			faces.reverse()  # land on different faces each cycle
			tumbler.begin_tumble(faces, locked, TUMBLE_S)
			next_tumble = now + int(TUMBLE_S * 1_000_000.0)
		tumbler.tick((now - last) / 1_000_000.0)
		await process_frame
		var after := Time.get_ticks_usec()
		frame_ms.append((after - now) / 1000.0)
		last = now
	frame_ms.sort()
	var total := 0.0
	for ms in frame_ms:
		total += ms
	var avg := total / frame_ms.size()
	var p95 := frame_ms[int(frame_ms.size() * 0.95)]
	var worst := frame_ms[-1]
	var report := "\n".join([
		"# Dice renderer frame time (desktop stand-in, not a phone measurement)", "",
		"- Device: %s" % RenderingServer.get_video_adapter_name(),
		"- Renderer: %s, internal 1080×2400, 8 dice re-tumbling for %.0f s, vsync off" % [
			RenderingServer.get_current_rendering_method(), SECONDS],
		"- Frames: %d" % frame_ms.size(),
		"- Average: %.2f ms (%.0f fps)" % [avg, 1000.0 / avg],
		"- 95th percentile: %.2f ms" % p95,
		"- Worst: %.2f ms" % worst, "",
		"Budget target: 16.6 ms (60 fps) on a 2021 mid-range Android phone. A desktop GPU",
		"is several times faster, so this only shows the dice add no pathological cost.",
	])
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://build"))
	var f := FileAccess.open("res://build/perf_dice.md", FileAccess.WRITE)
	f.store_string(report + "\n")
	f.close()
	print(report)
	current_scene.queue_free()
	await process_frame
	quit()
