extends CanvasLayer
## In-game UI: build bar with tech gating, objectives, selection rectangle,
## status line, and the end-of-game message.

signal build_requested(building_id: String)
signal upgrade_requested

@onready var _buttons := {
	"hut": $BuildBar/HutButton,
	"archery_range": $BuildBar/ArcheryButton,
	"watchtower": $BuildBar/WatchtowerButton,
	"barracks": $BuildBar/BarracksButton,
	"workshop": $BuildBar/WorkshopButton,
	"grand_totem": $BuildBar/TotemButton,
}


func _ready() -> void:
	for id in _buttons:
		_buttons[id].pressed.connect(func(): build_requested.emit(id))
	$UpgradePanel/VBox/UpgradeButton.pressed.connect(func(): upgrade_requested.emit())


func set_build_state(id: String, enabled: bool, tooltip: String) -> void:
	var button: Button = _buttons[id]
	button.disabled = not enabled
	button.tooltip_text = tooltip


func set_objectives(text: String) -> void:
	$ObjectiveLabel.text = text


func show_upgrade(text: String, button_label: String, enabled: bool) -> void:
	$UpgradePanel.visible = true
	$UpgradePanel/VBox/Info.text = text
	$UpgradePanel/VBox/UpgradeButton.text = button_label
	$UpgradePanel/VBox/UpgradeButton.disabled = not enabled


func hide_upgrade() -> void:
	$UpgradePanel.visible = false


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
