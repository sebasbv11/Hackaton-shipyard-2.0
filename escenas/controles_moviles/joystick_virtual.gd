extends Control

## Joystick táctil: emite dirección normalizada (-1..1).

signal direction_changed(direction: Vector2)

@export var deadzone := 0.18
@export var radius := 40.0

var direction := Vector2.ZERO
var _pointer_id := -1
var _center := Vector2.ZERO
var _knob: Panel


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	custom_minimum_size = Vector2(radius * 2.0 + 24.0, radius * 2.0 + 24.0)
	_build_visuals()
	resized.connect(_layout_visuals)
	call_deferred("_layout_visuals")


func _build_visuals() -> void:
	var base := Panel.new()
	base.name = "Base"
	base.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(base)

	_knob = Panel.new()
	_knob.name = "Knob"
	_knob.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_knob)


func _layout_visuals() -> void:
	var size := get_size()
	_center = size * 0.5
	var base: Panel = get_node("Base") as Panel
	base.position = _center - Vector2(radius + 4.0, radius + 4.0)
	base.size = Vector2(radius * 2.0 + 8.0, radius * 2.0 + 8.0)
	base.add_theme_stylebox_override("panel", _circle_style(Color(0.04, 0.18, 0.27, 0.55), radius + 4.0))
	var knob_size := radius * 0.72
	_knob.size = Vector2(knob_size, knob_size)
	_knob.position = _center - _knob.size * 0.5
	_knob.add_theme_stylebox_override("panel", _circle_style(Color("#e76f51"), knob_size * 0.5))


func _circle_style(color: Color, r: float) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = int(r)
	style.corner_radius_top_right = int(r)
	style.corner_radius_bottom_left = int(r)
	style.corner_radius_bottom_right = int(r)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color("#f4a261")
	return style


func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed:
			if _pointer_id == -1:
				_pointer_id = touch.index
				_move_knob(touch.position)
		elif touch.index == _pointer_id:
			_reset_knob()
	elif event is InputEventScreenDrag and event.index == _pointer_id:
		_move_knob(event.position)
	elif event is InputEventMouseButton:
		var mouse := event as InputEventMouseButton
		if mouse.button_index == MOUSE_BUTTON_LEFT:
			if mouse.pressed:
				_pointer_id = 0
				_move_knob(mouse.position)
			elif _pointer_id == 0:
				_reset_knob()
	elif event is InputEventMouseMotion and _pointer_id == 0 and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		_move_knob(event.position)


func _move_knob(local_pos: Vector2) -> void:
	var delta := local_pos - _center
	var dist := delta.length()
	if dist > radius:
		delta = delta / dist * radius
	_knob.position = _center + delta - _knob.size * 0.5
	var norm := Vector2.ZERO if dist < 8.0 else delta / radius
	direction = norm
	direction_changed.emit(direction)


func _reset_knob() -> void:
	_pointer_id = -1
	direction = Vector2.ZERO
	_knob.position = _center - _knob.size * 0.5
	direction_changed.emit(direction)
