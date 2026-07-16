extends CanvasLayer
## In-game UI: selection drag rectangle, status line, end-of-game message.


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
