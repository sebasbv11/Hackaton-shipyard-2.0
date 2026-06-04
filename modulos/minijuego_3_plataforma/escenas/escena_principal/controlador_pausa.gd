extends Node


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pausa"):
		if has_node("/root/MenuPausa"):
			get_viewport().set_input_as_handled()
			return
		get_tree().paused = !get_tree().paused
