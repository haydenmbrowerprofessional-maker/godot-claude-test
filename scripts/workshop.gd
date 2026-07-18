extends Destructible
## Tech building: boosts all friendly unit damage while it stands.

const DAMAGE_BONUS := 0.3


func _setup() -> void:
	var state := get_node_or_null("/root/GameState")
	if state:
		state.damage_multiplier += DAMAGE_BONUS
		died.connect(func(_b): state.damage_multiplier -= DAMAGE_BONUS)
