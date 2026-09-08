extends SceneTree
## Dev tool: renders the given models/scenes side by side on a neutral
## backdrop and saves a PNG, so art can be reviewed without the editor.
## Run: godot --path . -s tools/preview.gd -- res://path/a.glb res://path/b.tscn

const DEFAULTS := [
	"res://assets/scenery/tree.glb",
	"res://assets/buildings/wall.glb",
	"res://scenes/buildings/hut.tscn",
	"res://scenes/unit_blue.tscn",
]

var frames := 0


func _init() -> void:
	process_frame.connect(_on_frame)


func _build() -> void:
	var paths := DEFAULTS
	var args := OS.get_cmdline_user_args()
	if not args.is_empty():
		paths = args

	var world := Node3D.new()
	root.add_child(world)

	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-45, -35, 0)
	world.add_child(light)

	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.5, 0.55, 0.6)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.6, 0.6, 0.65)
	e.ambient_light_energy = 0.6
	env.environment = e
	world.add_child(env)

	var spacing := 4.0
	var count := paths.size()
	for i in count:
		var node: Node3D = (load(paths[i]) as PackedScene).instantiate()
		node.position = Vector3((i - (count - 1) / 2.0) * spacing, 0, 0)
		world.add_child(node)
		# Freeze anything that would move or fall during the capture.
		for n in node.find_children("*", "CharacterBody3D", true, false) + [node]:
			if n is CharacterBody3D:
				n.set_physics_process(false)
		print("[%d] %s at x=%.1f" % [i, paths[i].get_file(), node.position.x])

	var cam := Camera3D.new()
	cam.position = Vector3(0, 3.2, spacing * count * 0.55 + 3.0)
	world.add_child(cam)
	cam.look_at(Vector3(0, 1.0, 0))


func _on_frame() -> void:
	frames += 1
	if frames == 1:
		_build()
		return
	if frames < 60:
		return
	root.get_texture().get_image().save_png("user://preview.png")
	print("SAVED: ", ProjectSettings.globalize_path("user://preview.png"))
	quit()
