extends SceneTree
## Dev tool: plays the real map with vsync off and reports frame timing, to
## check size-over-speed build flags don't cost noticeable performance.
## Spawns extra fights so there's real physics/combat work to measure.
## Run (not headless): godot --path . -s tools/perf_probe.gd

const WARMUP := 120
const SAMPLES := 900

var frames := 0
var started := 0
var worst_ms := 0.0
var last_ticks := 0


func _init() -> void:
	change_scene_to_file.call_deferred("res://scenes/main.tscn")
	process_frame.connect(_on_frame)


func _on_frame() -> void:
	frames += 1
	if frames == 2:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
		# Stage a 12v12 brawl in view of the camera.
		var blue: PackedScene = load("res://scenes/unit_blue.tscn")
		var red: PackedScene = load("res://scenes/unit_red.tscn")
		var units := current_scene.get_node("Units")
		for i in 12:
			for pair in [[blue, 17.0], [red, 12.0]]:
				var u: Node3D = pair[0].instantiate()
				u.position = Vector3(14.0 + (i % 6) * 1.2, 0.1, pair[1] + floorf(i / 6.0) * 1.2)
				units.add_child(u)
	if frames == WARMUP:
		started = Time.get_ticks_usec()
		last_ticks = started
	elif frames > WARMUP:
		var now := Time.get_ticks_usec()
		worst_ms = maxf(worst_ms, (now - last_ticks) / 1000.0)
		last_ticks = now
		if frames == WARMUP + SAMPLES:
			var avg_ms := (now - started) / 1000.0 / SAMPLES
			print("PERF: avg %.2f ms/frame (%.0f fps), worst %.2f ms over %d frames" % [avg_ms, 1000.0 / avg_ms, worst_ms, SAMPLES])
			quit()
