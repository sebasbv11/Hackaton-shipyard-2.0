extends Node2D

const ACTION_LEFT := "izquierda"
const ACTION_RIGHT := "derecha"
const ACTION_JUMP := "saltar"
const W := 1280.0
const H := 720.0

@export var ruta_minijuego_1 := "res://modulos/minijuego_1/escenas/minijuego_1/intro.tscn"
@export var ruta_minijuego_2_plataforma := "res://modulos/minijuego_3_plataforma/escenas/escena_principal/escena_principal.tscn"
@export var ruta_minijuego_3_flappy := "res://modulos/minijuego_4_flappy/escenas/minijuego_4_flappy/FlappyPescador.tscn"
@export var animacion: AnimatedSprite2D
@export var mensaje: Label

var _player_position := Vector2(640.0, 560.0)
var _velocity := Vector2.ZERO
var _speed := 360.0
var _jump_speed := -520.0
var _gravity := 1500.0
var _ground_y := 560.0
var _facing_left := false
var _active_boat := -1
var _boats := [
	{"id": 1, "x": 250.0, "title": "Minijuego 1"},
	{"id": 2, "x": 640.0, "title": "Plataforma"},
	{"id": 3, "x": 1030.0, "title": "Flappy"}
]
var _pressed_actions := {}


func _ready() -> void:
	if is_instance_valid(animacion):
		animacion.play("idle")
		animacion.scale = Vector2(2.7, 2.7)
		_update_player_visual()
	if is_instance_valid(mensaje):
		mensaje.text = "Camina al barco 1 y toca OK para entrar al minijuego 1."
	_create_mobile_controls()


func _physics_process(delta: float) -> void:
	var direction := Input.get_axis(ACTION_LEFT, ACTION_RIGHT)
	_velocity.x = direction * _speed
	_player_position.x = clampf(_player_position.x + _velocity.x * delta, 70.0, W - 70.0)

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
	draw_rect(Rect2(Vector2.ZERO, Vector2(W, H)), Color("#79d5ee"))
	draw_rect(Rect2(0.0, 250.0, W, H - 250.0), Color("#147fa4"))
	for i in range(18):
		var y := 270.0 + float(i) * 22.0 + sin(Time.get_ticks_msec() / 450.0 + i) * 4.0
		draw_rect(Rect2(0.0, y, W, 5.0), Color(0.70, 0.95, 1.0, 0.25))
	draw_rect(Rect2(0.0, 448.0, W, 24.0), Color("#e0bd77"))
	draw_rect(Rect2(0.0, 472.0, W, 14.0), Color("#8c5429"))


func _draw_dock() -> void:
	draw_rect(Rect2(0.0, 500.0, W, 150.0), Color("#7d4b28"))
	for x in range(0, int(W), 88):
		draw_rect(Rect2(float(x), 500.0, 70.0, 150.0), Color("#a46535"))
		draw_rect(Rect2(float(x) + 70.0, 500.0, 7.0, 150.0), Color("#503018"))
	for x in range(56, int(W), 180):
		draw_rect(Rect2(float(x), 430.0, 24.0, 220.0), Color("#533018"))
		draw_rect(Rect2(float(x) - 8.0, 416.0, 40.0, 16.0), Color("#332012"))


func _draw_boats() -> void:
	for boat in _boats:
		var x: float = boat.x
		var active := int(boat.id) == _active_boat
		var hull_color := Color("#f4a261") if active else Color("#7a3f24")
		draw_rect(Rect2(x - 96.0, 326.0, 192.0, 36.0), hull_color)
		draw_rect(Rect2(x - 72.0, 286.0, 144.0, 44.0), Color("#b45f2b"))
		draw_rect(Rect2(x - 46.0, 238.0, 92.0, 58.0), Color("#e8c37a"))
		draw_rect(Rect2(x - 5.0, 150.0, 10.0, 116.0), Color("#4d2d18"))
		var sail_color := Color("#d94f3d")
		draw_polygon(
			PackedVector2Array([Vector2(x + 8.0, 160.0), Vector2(x + 92.0, 208.0), Vector2(x + 8.0, 260.0)]),
			PackedColorArray([sail_color, sail_color, sail_color])
		)
		draw_string(ThemeDB.fallback_font, Vector2(x - 72.0, 398.0), str(boat.title), HORIZONTAL_ALIGNMENT_LEFT, 150.0, 24, Color.WHITE)


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
		mensaje.text = "Barco 2: toca OK para entrar al minijuego de plataforma."
	elif _active_boat == 3:
		mensaje.text = "Barco 3: toca OK para entrar a Flappy Pescador."
	else:
		mensaje.text = "Camina al barco 1 y toca OK para entrar al minijuego 1."


func _interact() -> void:
	if _active_boat == 1 and not ruta_minijuego_1.is_empty():
		get_tree().change_scene_to_file(ruta_minijuego_1)
	elif _active_boat == 2 and not ruta_minijuego_2_plataforma.is_empty():
		_reiniciar_progreso_plataforma()
		get_tree().change_scene_to_file(ruta_minijuego_2_plataforma)
	elif _active_boat == 3 and not ruta_minijuego_3_flappy.is_empty():
		get_tree().change_scene_to_file(ruta_minijuego_3_flappy)
	elif is_instance_valid(mensaje):
		mensaje.text = "Selecciona un barco disponible."


func _reiniciar_progreso_plataforma() -> void:
	ControladorGlobal.nivel = 1
	ControladorGlobal.muertes = 0


func _create_mobile_controls() -> void:
	var layer := CanvasLayer.new()
	layer.name = "ControlesLobby"
	add_child(layer)

	_add_hold_button(layer, "Izquierda", "<", ACTION_LEFT, Vector2(34.0, H - 118.0), Vector2(118.0, 96.0))
	_add_hold_button(layer, "Derecha", ">", ACTION_RIGHT, Vector2(172.0, H - 118.0), Vector2(118.0, 96.0))
	_add_hold_button(layer, "Saltar", "^", ACTION_JUMP, Vector2(W - 168.0, H - 128.0), Vector2(136.0, 106.0))

	var ok := Button.new()
	ok.name = "Interactuar"
	ok.text = "OK"
	ok.focus_mode = Control.FOCUS_NONE
	ok.position = Vector2(W - 330.0, H - 118.0)
	ok.size = Vector2(128.0, 96.0)
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
