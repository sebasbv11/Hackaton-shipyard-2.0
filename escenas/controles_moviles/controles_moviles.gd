extends Control

## Controles landscape: joystick abajo-izquierda, acciones abajo-derecha.

signal interact_pressed

const ACTION_LEFT := "izquierda"
const ACTION_RIGHT := "derecha"
const ACTION_JUMP := "saltar"

@export var show_jump := true
@export var show_interact := false
@export var interact_label := "OK"

var _pressed_actions: Dictionary = {}
var _joystick: Control
var _btn_jump: Button
var _btn_interact: Button
var _left_zone: Control
var _right_zone: Control

const JOYSTICK_SCENE := preload("res://escenas/controles_moviles/joystick_virtual.tscn")


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_layout()
	resized.connect(_layout_controls)
	call_deferred("_layout_controls")


func _exit_tree() -> void:
	_release_all_actions()


func _build_layout() -> void:
	_left_zone = Control.new()
	_left_zone.name = "LeftZone"
	_left_zone.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_left_zone)

	_joystick = JOYSTICK_SCENE.instantiate()
	_joystick.name = "Joystick"
	_joystick.direction_changed.connect(_on_joystick_direction)
	_left_zone.add_child(_joystick)

	_right_zone = Control.new()
	_right_zone.name = "RightZone"
	_right_zone.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_right_zone)

	_btn_jump = _make_action_button("Saltar", "^")
	_btn_jump.visible = show_jump
	_btn_jump.button_down.connect(func() -> void: _press_action(ACTION_JUMP))
	_btn_jump.button_up.connect(func() -> void: _release_action(ACTION_JUMP))
	_right_zone.add_child(_btn_jump)

	_btn_interact = _make_action_button("Interactuar", interact_label)
	_btn_interact.visible = show_interact
	_btn_interact.pressed.connect(func() -> void: interact_pressed.emit())
	_right_zone.add_child(_btn_interact)


func _make_action_button(node_name: String, label: String) -> Button:
	var button := Button.new()
	button.name = node_name
	button.text = label
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	button.modulate = Color(1.0, 1.0, 1.0, 0.88)
	button.add_theme_font_size_override("font_size", 28)
	return button


func _layout_controls() -> void:
	var viewport_size := get_viewport_rect().size
	var pad := 16.0 + _safe_margin_bottom()
	var side_pad := 14.0 + _safe_margin_horizontal()

	var joy_size := 108.0
	if viewport_size.y < 400.0:
		joy_size = 88.0
	_joystick.custom_minimum_size = Vector2(joy_size, joy_size)
	_joystick.size = Vector2(joy_size, joy_size)

	var btn_size := Vector2(72.0, 72.0)
	if viewport_size.y < 400.0:
		btn_size = Vector2(60.0, 60.0)

	_left_zone.position = Vector2(side_pad, viewport_size.y - joy_size - pad)
	_left_zone.size = Vector2(joy_size, joy_size)

	var right_x := viewport_size.x - side_pad - btn_size.x
	var right_y := viewport_size.y - pad - btn_size.y
	if show_interact and show_jump:
		_btn_interact.position = Vector2(0.0, 0.0)
		_btn_interact.size = btn_size
		_btn_jump.position = Vector2(0.0, -btn_size.y - 10.0)
		_btn_jump.size = btn_size
		_right_zone.position = Vector2(right_x, right_y - btn_size.y - 10.0)
		_right_zone.size = Vector2(btn_size.x, btn_size.y * 2.0 + 10.0)
	elif show_jump:
		_btn_jump.position = Vector2.ZERO
		_btn_jump.size = btn_size
		_right_zone.position = Vector2(right_x, right_y)
		_right_zone.size = btn_size
	else:
		_btn_interact.position = Vector2.ZERO
		_btn_interact.size = btn_size
		_right_zone.position = Vector2(right_x, right_y)
		_right_zone.size = btn_size


func _safe_margin_bottom() -> float:
	return DisplayServer.get_display_safe_area().size.y * 0.0


func _safe_margin_horizontal() -> float:
	return 0.0


func _on_joystick_direction(dir: Vector2) -> void:
	var x := dir.x
	if x < -0.25:
		_press_action(ACTION_LEFT)
		_release_action(ACTION_RIGHT)
	elif x > 0.25:
		_press_action(ACTION_RIGHT)
		_release_action(ACTION_LEFT)
	else:
		_release_action(ACTION_LEFT)
		_release_action(ACTION_RIGHT)


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


func _release_all_actions() -> void:
	for action: String in _pressed_actions.keys():
		Input.action_release(action)
	_pressed_actions.clear()


func set_interact_visible(visible: bool) -> void:
	show_interact = visible
	if is_instance_valid(_btn_interact):
		_btn_interact.visible = visible
	_layout_controls()
