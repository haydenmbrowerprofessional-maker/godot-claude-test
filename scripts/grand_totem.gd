extends Destructible
## Victory monument: completing it wins the game.


func _setup() -> void:
	var state := get_node_or_null("/root/GameState")
	if state:
		state.totem_built.emit()
