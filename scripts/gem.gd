extends Area3D
## Hidden collectible: a friendly unit walking over it picks it up.


func _process(delta: float) -> void:
	rotate_y(1.6 * delta)


func _on_body_entered(body: Node3D) -> void:
	if body is Unit and body.team == 0:
		var state := get_node_or_null("/root/GameState")
		if state:
			state.collect_gem()
		queue_free()
