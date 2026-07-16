extends SceneTree
## Dev tool: prints world-space size and animation names for imported models.
## Run: godot --headless -s tools/inspect_assets.gd [-- res://path/to/model.glb ...]

const DEFAULT_PATHS := [
	"res://assets/buildings/windmill.glb",
	"res://assets/buildings/watermill.glb",
	"res://assets/buildings/banner-red.glb",
]


func _init() -> void:
	var paths := DEFAULT_PATHS
	var args := OS.get_cmdline_user_args()
	if not args.is_empty():
		paths = args
	for path: String in paths:
		var scene: PackedScene = load(path)
		var node: Node3D = scene.instantiate()
		root.add_child(node)
		var aabb := _combined_aabb(node)
		print(path.get_file(), " size=", aabb.size, " pos=", aabb.position)
		for p in node.find_children("*", "AnimationPlayer", true, false):
			print("  animations: ", p.get_animation_list())
		node.free()
	quit()


func _combined_aabb(node: Node3D) -> AABB:
	var result := AABB()
	var first := true
	for mesh: MeshInstance3D in node.find_children("*", "MeshInstance3D", true, false):
		var ab: AABB = mesh.global_transform * mesh.get_aabb()
		if first:
			result = ab
			first = false
		else:
			result = result.merge(ab)
	return result
