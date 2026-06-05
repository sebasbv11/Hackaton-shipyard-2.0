extends Control

@export_enum("plataforma", "minijuego_1_salto", "minijuego_1_pesca") var modo := "plataforma"

var _buttons: Dictionary = {}
var _active_touches: Dictionary = {}
var _pressed_actions: Dictionary = {}
var _mouse_action := ""


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	process_mode = Node.PROCESS_MODE_ALWAYS
	resized.connect(_update_button_positions)
	_create_buttons()
	_update_button_positions()


func _exit_tree() -> void:
	for action: String in _pressed_actions.keys():
		Input.action_release(action)
	_pressed_actions.clear()


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		var handled := false
		if touch.pressed:
			handled = _press_touch(touch.index, touch.position)
		else:
			handled = _release_touch(touch.index)
		if handled:
			get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton:
		var mouse := event as InputEventMouseButton
		if mouse.button_index != MOUSE_BUTTON_LEFT:
			return
		if mouse.pressed:
			_mouse_action = _action_at(mouse.position)
			if not _mouse_action.is_empty():
				_press_action(_mouse_action)
				get_viewport().set_input_as_handled()
		else:
			if not _mouse_action.is_empty():
				_release_action(_mouse_action)
				_mouse_action = ""
				get_viewport().set_input_as_handled()


func _create_buttons() -> void:
	for child in get_children():
		child.queue_free()
	_buttons.clear()

	if modo == "plataforma":
		_add_button("izquierda", "<", 38)
		_add_button("derecha", ">", 38)
		_add_button("saltar", "SALTO", 30)
	elif modo == "minijuego_1_salto":
		_add_button("ui_accept", "SALTAR", 30)
	elif modo == "minijuego_1_pesca":
		_add_button("ui_accept", "PESCAR", 30)


func _add_button(action: String, label: String, font_size: int) -> void:
	var button := Button.new()
	button.name = action
	button.text = label
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.modulate = Color(1.0, 1.0, 1.0, 0.88)
	button.add_theme_font_size_override("font_size", font_size)
	_buttons[action] = button
	add_child(button)


func _update_button_positions() -> void:
	var s := get_viewport_rect().size
	if modo == "plataforma":
		_set_button_bounds("izquierda", Vector2(34.0, s.y - 142.0), Vector2(118.0, 100.0))
		_set_button_bounds("derecha", Vector2(172.0, s.y - 142.0), Vector2(118.0, 100.0))
		_set_button_bounds("saltar", Vector2(s.x - 190.0, s.y - 166.0), Vector2(156.0, 132.0))
	elif modo == "minijuego_1_salto":
		_set_button_bounds("ui_accept", Vector2(s.x - 218.0, s.y - 162.0), Vector2(184.0, 124.0))
	elif modo == "minijuego_1_pesca":
		_set_button_bounds("ui_accept", Vector2(s.x - 210.0, s.y - 162.0), Vector2(176.0, 124.0))


func _set_button_bounds(action: String, position: Vector2, size: Vector2) -> void:
	if not _buttons.has(action):
		return
	var button: Button = _buttons[action]
	button.position = position
	button.size = size


func _press_touch(index: int, position: Vector2) -> bool:
	var action := _action_at(position)
	if action.is_empty():
		return false
	_active_touches[index] = action
	_press_action(action)
	return true


func _release_touch(index: int) -> bool:
	if not _active_touches.has(index):
		return false
	var action := String(_active_touches[index])
	_active_touches.erase(index)
	for other_action in _active_touches.values():
		if String(other_action) == action:
			return true
	_release_action(action)
	return true


func _action_at(position: Vector2) -> String:
	for action: String in _buttons.keys():
		var button: Button = _buttons[action]
		if button.get_global_rect().has_point(position):
			return action
	return ""


func _press_action(action: String) -> void:
	if _pressed_actions.has(action):
		return
	_pressed_actions[action] = true
	Input.action_press(action)
	_set_button_pressed(action, true)


func _release_action(action: String) -> void:
	if not _pressed_actions.has(action):
		return
	_pressed_actions.erase(action)
	Input.action_release(action)
	_set_button_pressed(action, false)


func _set_button_pressed(action: String, pressed: bool) -> void:
	if _buttons.has(action):
		var button: Button = _buttons[action]
		button.button_pressed = pressed
