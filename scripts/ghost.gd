extends MeshInstance3D
## Placement preview disc: green when the spot is valid, red when not.


func set_valid(valid: bool) -> void:
	var mat := material_override as StandardMaterial3D
	mat.albedo_color = Color(0.3, 1.0, 0.4, 0.4) if valid else Color(1.0, 0.25, 0.2, 0.4)
