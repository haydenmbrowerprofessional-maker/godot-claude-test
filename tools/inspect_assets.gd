extends SceneTree
## Dev tool: prints size and animation names for imported character models.


func _init() -> void:
	for path in ["res://assets/characters/character-male-a.glb", "res://assets/scenery/tree.glb", "res://assets/scenery/flag.glb"]:
		var scene: PackedScene = load(path)
		var node := scene.instantiate()
		var aabb := _combined_aabb(node)
		print(path.get_file(), " size=", aabb.size, " pos=", aabb.position)
		var players := node.find_children("*", "AnimationPlayer", true, false)
		for p in players:
			print("  animations: ", p.get_animation_list())
		node.free()
	quit()


func _combined_aabb(node: Node) -> AABB:
	var result := AABB()
	var first := true
	for mesh in node.find_children("*", "MeshInstance3D", true, false):
		var ab: AABB = mesh.get_aabb() * mesh.transform.affine_inverse() if false else mesh.get_aabb()
		if first:
			result = ab
			first = false
		else:
			result = result.merge(ab)
	return result
