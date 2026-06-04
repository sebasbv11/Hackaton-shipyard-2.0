extends Node2D

const ACTION_LEFT := "izquierda"
const ACTION_RIGHT := "derecha"
const ACTION_JUMP := "saltar"

@export var ruta_minijuego_1 := "res://modulos/minijuego_1/escenas/minijuego_1/intro.tscn"
@export var ruta_minijuego_3 := "res://modulos/minijuego_3_plataforma/escenas/escena_principal/escena_principal.tscn"
@export var ruta_minijuego_4 := "res://modulos/minijuego_4_flappy/escenas/minijuego_4_flappy/FlappyPescador.tscn"
@export var animacion: AnimatedSprite2D
@export var mensaje: Label

var _player_position := Vector2(360.0, 1030.0)
var _velocity := Vector2.ZERO
var _speed := 260.0
var _jump_speed := -560.0
var _gravity := 1500.0
var _ground_y := 1030.0
var _facing_left := false
var _active_boat := -1
var _boats := [
	{"id": 1, "x": 100.0, "title": "Minijuego 1", "status": "Disponible"},
	{"id": 2, "x": 275.0, "title": "Minijuego 2", "status": "Pendiente"},
	{"id": 3, "x": 450.0, "title": "Plataforma", "status": "Disponible"},
	{"id": 4, "x": 625.0, "title": "Flappy", "status": "Disponible"}
]
var _pressed_actions := {}


func _ready() -> void:
	if is_instance_valid(animacion):
		animacion.play("idle")
		animacion.scale = Vector2(3.0, 3.0)
		_update_player_visual()
	if is_instance_valid(mensaje):
		mensaje.text = "Camina al barco 1 y toca OK para entrar al minijuego 1."
	_create_mobile_controls()


func _physics_process(delta: float) -> void:
	var direction := Input.get_axis(ACTION_LEFT, ACTION_RIGHT)
	_velocity.x = direction * _speed
	_player_position.x = clampf(_player_position.x + _velocity.x * delta, 54.0, 666.0)

	if direction < 0.0:
		_facing_left = true
	elif direction > 0.0:
		_facing_left = false

	if Input.is_action_just_pressed(ACTION_JUMP) and _is_on_ground():
		_velocity.y = _jump_speed

	_velocity.y += _gravity * delta
	_player_position.y += _velocity.y * delta
	if _player_position.y >= _ground_y:
		_player_position.y = _ground_y
		_velocity.y = 0.0

	_update_active_boat()
	_update_player_visual()
	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		_interact()


func _draw() -> void:
	_draw_background()
	_draw_boats()
	_draw_dock()


func _draw_background() -> void:
	draw_rect(Rect2(Vector2.ZERO, Vector2(720.0, 1280.0)), Color("#79d5ee"))
	draw_rect(Rect2(0.0, 360.0, 720.0, 920.0), Color("#147fa4"))
	for i in range(18):
		var y := 390.0 + float(i) * 42.0 + sin(Time.get_ticks_msec() / 450.0 + i) * 5.0
		draw_rect(Rect2(0.0, y, 720.0, 6.0), Color(0.70, 0.95, 1.0, 0.25))
	draw_rect(Rect2(0.0, 825.0, 720.0, 28.0), Color("#e0bd77"))
	draw_rect(Rect2(0.0, 853.0, 720.0, 16.0), Color("#8c5429"))


func _draw_dock() -> void:
	draw_rect(Rect2(0.0, 885.0, 720.0, 240.0), Color("#7d4b28"))
	for x in range(0, 720, 72):
		draw_rect(Rect2(float(x), 885.0, 56.0, 240.0), Color("#a46535"))
		draw_rect(Rect2(float(x) + 56.0, 885.0, 6.0, 240.0), Color("#503018"))
	for x in range(44, 720, 150):
		draw_rect(Rect2(float(x), 820.0, 22.0, 300.0), Color("#533018"))
		draw_rect(Rect2(float(x) - 8.0, 806.0, 38.0, 16.0), Color("#332012"))


func _draw_boats() -> void:
	for boat in _boats:
		var x: float = boat.x
		var active := int(boat.id) == _active_boat
		var hull_color := Color("#f4a261") if active else Color("#7a3f24")
		draw_rect(Rect2(x - 78.0, 585.0, 156.0, 34.0), hull_color)
		draw_rect(Rect2(x - 60.0, 548.0, 120.0, 42.0), Color("#b45f2b"))
		draw_rect(Rect2(x - 40.0, 506.0, 80.0, 56.0), Color("#e8c37a"))
		draw_rect(Rect2(x - 5.0, 428.0, 10.0, 100.0), Color("#4d2d18"))
		var sail_color := Color("#f4e4bc") if int(boat.id) == 2 else Color("#d94f3d")
		draw_polygon(
			PackedVector2Array([Vector2(x + 8.0, 438.0), Vector2(x + 78.0, 478.0), Vector2(x + 8.0, 520.0)]),
			PackedColorArray([sail_color, sail_color, sail_color])
		)
		draw_string(ThemeDB.fallback_font, Vector2(x - 54.0, 670.0), str(boat.title), HORIZONTAL_ALIGNMENT_LEFT, 120.0, 24, Color.WHITE)
		draw_string(ThemeDB.fallback_font, Vector2(x - 42.0, 700.0), str(boat.status), HORIZONTAL_ALIGNMENT_LEFT, 100.0, 18, Color("#f4e4bc"))


func _update_player_visual() -> void:
	if not is_instance_valid(animacion):
		return
	animacion.global_position = _player_position
	animacion.flip_h = _facing_left
	if not _is_on_ground():
		animacion.play("saltar")
	elif absf(_velocity.x) > 1.0:
		animacion.play("correr")
	else:
		animacion.play("idle")


func _is_on_ground() -> bool:
	return is_equal_approx(_player_position.y, _ground_y)


func _update_active_boat() -> void:
	var closest := -1
	var closest_distance := 99999.0
	for boat in _boats:
		var distance := absf(float(boat.x) - _player_position.x)
		if distance < closest_distance:
			closest_distance = distance
			closest = int(boat.id)

	_active_boat = closest if closest_distance <= 96.0 else -1
	if not is_instance_valid(mensaje):
		return
	if _active_boat == 1:
		mensaje.text = "Barco 1: toca OK para entrar al minijuego 1."
	elif _active_boat == 2:
		mensaje.text = "Barco 2: minijuego pendiente de conectar."
	elif _active_boat == 3:
		mensaje.text = "Barco 3: toca OK para entrar al minijuego de plataforma."
	elif _active_boat == 4:
		mensaje.text = "Barco 4: toca OK para entrar a Flappy Pescador."
	else:
		mensaje.text = "Camina al barco 1 y toca OK para entrar al minijuego 1."


func _interact() -> void:
	if _active_boat == 1 and not ruta_minijuego_1.is_empty():
		get_tree().change_scene_to_file(ruta_minijuego_1)
	elif _active_boat == 3 and not ruta_minijuego_3.is_empty():
		get_tree().change_scene_to_file(ruta_minijuego_3)
	elif _active_boat == 4 and not ruta_minijuego_4.is_empty():
		get_tree().change_scene_to_file(ruta_minijuego_4)
	elif is_instance_valid(mensaje):
		mensaje.text = "Ese barco aun no tiene minijuego conectado."


func _create_mobile_controls() -> void:
	var layer := CanvasLayer.new()
	layer.name = "ControlesLobby"
	add_child(layer)

	_add_hold_button(layer, "Izquierda", "<", ACTION_LEFT, Vector2(32.0, 1110.0), Vector2(120.0, 100.0))
	_add_hold_button(layer, "Derecha", ">", ACTION_RIGHT, Vector2(172.0, 1110.0), Vector2(120.0, 100.0))
	_add_hold_button(layer, "Saltar", "^", ACTION_JUMP, Vector2(548.0, 1095.0), Vector2(120.0, 100.0))

	var ok := Button.new()
	ok.name = "Interactuar"
	ok.text = "OK"
	ok.focus_mode = Control.FOCUS_NONE
	ok.position = Vector2(395.0, 1110.0)
	ok.size = Vector2(120.0, 100.0)
	ok.add_theme_font_size_override("font_size", 34)
	ok.pressed.connect(_interact)
	layer.add_child(ok)


func _add_hold_button(parent: Node, node_name: String, label: String, action: String, position: Vector2, size: Vector2) -> void:
	var button := Button.new()
	button.name = node_name
	button.text = label
	button.focus_mode = Control.FOCUS_NONE
	button.position = position
	button.size = size
	button.add_theme_font_size_override("font_size", 34)
	button.button_down.connect(func() -> void: _press_action(action))
	button.button_up.connect(func() -> void: _release_action(action))
	parent.add_child(button)


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
