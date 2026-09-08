extends SceneTree
## Dev tool: prints which texture each model's material actually binds.
## Catches cross-kit colormap mix-ups (Kenney kits ship different palettes).
## Run: godot --headless -s tools/inspect_materials.gd

const PATHS := [
	"res://assets/scenery/tree.glb",
	"res://assets/scenery/tree-pine.glb",
	"res://assets/buildings/wall.glb",
	"res://assets/buildings/stall.glb",
	"res://assets/characters/character-male-a.glb",
]


func _init() -> void:
	for path: String in PATHS:
		var node: Node3D = (load(path) as PackedScene).instantiate()
		root.add_child(node)
		print(path.get_file(), ":")
		for mesh: MeshInstance3D in node.find_children("*", "MeshInstance3D", true, false):
			var m: Mesh = mesh.mesh
			for i in m.get_surface_count():
				var mat := m.surface_get_material(i) as StandardMaterial3D
				if mat == null:
					print("   surface ", i, ": <non-standard material>")
					continue
				var tex := mat.albedo_texture
				print("   surface %d: albedo_tex=%s color=%s" % [
					i, tex.resource_path if tex else "<none>", mat.albedo_color])
		node.free()
	quit()
