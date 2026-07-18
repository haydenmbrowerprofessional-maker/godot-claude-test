extends CanvasLayer
## In-game UI: build bar with tech gating, objectives, selection rectangle,
## status line, and the end-of-game message.

signal build_requested(building_id: String)

@onready var _buttons := {
	"hut": $BuildBar/HutButton,
	"watchtower": $BuildBar/WatchtowerButton,
	"workshop": $BuildBar/WorkshopButton,
	"grand_totem": $BuildBar/TotemButton,
}


func _ready() -> void:
	for id in _buttons:
		_buttons[id].pressed.connect(func(): build_requested.emit(id))


func set_build_state(id: String, enabled: bool, tooltip: String) -> void:
	var button: Button = _buttons[id]
	button.disabled = not enabled
	button.tooltip_text = tooltip


func set_objectives(text: String) -> void:
	$ObjectiveLabel.text = text


func set_drag_rect(rect: Rect2) -> void:
	$SelectionRect.set_drag(rect)


func clear_drag() -> void:
	$SelectionRect.clear()


func set_selected_count(count: int) -> void:
	$InfoLabel.text = "Selected: %d    |    LMB drag: select   RMB: move / attack   WASD: pan   Wheel: zoom" % count


func show_end(message: String) -> void:
	$CenterMessage.text = message
	$CenterMessage.show()
	$RestartButton.show()


func _on_restart_button_pressed() -> void:
	get_tree().reload_current_scene()
