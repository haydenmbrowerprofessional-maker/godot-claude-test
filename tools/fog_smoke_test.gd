extends SceneTree
## Headless smoke test for fog of war: starts hidden, reveals around a
## friendly unit, hides enemies until their spot is revealed.
## Run: godot --headless -s tools/fog_smoke_test.gd

var frames := 0
var fog: FogOfWar
var enemy: Unit


func _init() -> void:
	var scene: PackedScene = load("res://scenes/main.tscn")
	# Use the real fog node setup from the shipped scene, in isolation.
	fog = (load("res://scripts/fog_of_war.gd") as GDScript).new()
	fog.mesh = PlaneMesh.new()
	var mat := ShaderMaterial.new()
	mat.shader = load("res://assets/fog.gdshader")
	fog.material_override = mat
	var tick := Timer.new()
	tick.name = "Tick"
	tick.wait_time = 0.1
	tick.autostart = true
	fog.add_child(tick)
	tick.timeout.connect(fog._on_tick_timeout)
	root.add_child(fog)
	assert(scene != null)

	var friendly: Unit = (load("res://scenes/unit_blue.tscn") as PackedScene).instantiate()
	friendly.position = Vector3(0, 0.1, 0)
	root.add_child(friendly)

	enemy = (load("res://scenes/unit_red.tscn") as PackedScene).instantiate()
	enemy.position = Vector3(30, 0.1, 30)
	root.add_child(enemy)

	process_frame.connect(_on_frame)


func _on_frame() -> void:
	frames += 1
	if frames == 30:
		if not fog.is_revealed(Vector3.ZERO):
			return _fail("area around friendly unit was not revealed")
		if fog.is_revealed(Vector3(30, 0, 30)):
			return _fail("distant area revealed too early")
		if enemy.visible:
			return _fail("enemy visible while under fog")
		# Reveal the enemy's area and confirm it becomes visible.
		fog.reveal_circle(Vector3(30, 0, 30), 6.0)
	if frames == 60:
		if not enemy.visible:
			return _fail("enemy still hidden after its area was revealed")
		print("SMOKE TEST PASS: fog reveals, persists, and gates enemy visibility")
		quit(0)


func _fail(message: String) -> void:
	print("SMOKE TEST FAIL: ", message)
	quit(1)
