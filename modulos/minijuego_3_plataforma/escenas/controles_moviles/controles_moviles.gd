extends Control

const ACTION_LEFT := "izquierda"
const ACTION_RIGHT := "derecha"
const ACTION_JUMP := "saltar"

var _pressed_actions: Dictionary = {}
var _buttons: Dictionary = {}


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(_update_button_positions)
	_add_hold_button("Izquierda", "<", ACTION_LEFT)
	_add_hold_button("Derecha", ">", ACTION_RIGHT)
	_add_hold_button("Saltar", "^", ACTION_JUMP)
	_update_button_positions()


func _exit_tree() -> void:
	for action: String in _pressed_actions.keys():
		Input.action_release(action)
	_pressed_actions.clear()


func _add_hold_button(node_name: String, label: String, action: String) -> void:
	var button := Button.new()
	button.name = node_name
	button.text = label
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	button.modulate = Color(1.0, 1.0, 1.0, 0.82)
	button.add_theme_font_size_override("font_size", 34)
	button.button_down.connect(func() -> void: _press_action(action))
	button.button_up.connect(func() -> void: _release_action(action))
	_buttons[action] = button
	add_child(button)


func _update_button_positions() -> void:
	var viewport_size := get_viewport_rect().size
	var pad := 32.0
	var floor_y := viewport_size.y - 128.0 - pad

	_set_button_bounds(ACTION_LEFT, Vector2(pad, floor_y), Vector2(116.0, 96.0))
	_set_button_bounds(ACTION_RIGHT, Vector2(pad + 132.0, floor_y), Vector2(116.0, 96.0))
	_set_button_bounds(ACTION_JUMP, Vector2(viewport_size.x - 160.0, viewport_size.y - 160.0), Vector2(128.0, 128.0))


func _set_button_bounds(action: String, position: Vector2, size: Vector2) -> void:
	var button: Button = _buttons[action]
	button.position = position
	button.size = size


func _press_action(action: String) -> void:
	if _pressed_actions.has(action):
		return
	_pressed_actions[action] = true
	Input.action_press(action)


func _release_action(action: String) -> void:
	if not _pressed_actions.has(action):
		return
	_pressed_actions.erase(action)
	Input.action_release(action)
