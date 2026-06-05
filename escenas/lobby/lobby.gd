extends Node2D

const ACTION_LEFT := "izquierda"
const ACTION_RIGHT := "derecha"
const ACTION_JUMP := "saltar"
const VIEW_W := 1280.0
const VIEW_H := 720.0

@export var ruta_minijuego_2 := "res://escenas/escena_principal/escena_principal.tscn"
@export var ruta_minijuego_3 := "res://escenas/minijuego_3_flappy/FlappyPescador.tscn"
@export var animacion: AnimatedSprite2D
@export var mensaje: Label

var _player_position := Vector2(640.0, 598.0)
var _velocity := Vector2.ZERO
var _speed := 280.0
var _jump_speed := -520.0
var _gravity := 1500.0
var _ground_y := 598.0
var _facing_left := false
var _active_boat := -1
var _boats := [
	{"id": 1, "x": 280.0, "title": "Minijuego 1", "status": "Pendiente"},
	{"id": 2, "x": 640.0, "title": "Plataforma", "status": "Disponible"},
	{"id": 3, "x": 1000.0, "title": "Flappy", "status": "Disponible"}
]
var _controles: Control


func _ready() -> void:
	if is_instance_valid(animacion):
		animacion.play("idle")
		animacion.scale = Vector2(2.6, 2.6)
		_update_player_visual()
	if is_instance_valid(mensaje):
		mensaje.text = "Camina al barco 2 y pulsa OK para entrar al minijuego 2."
	_spawn_controls()


func _physics_process(delta: float) -> void:
	var direction := Input.get_axis(ACTION_LEFT, ACTION_RIGHT)
	_velocity.x = direction * _speed
	_player_position.x = clampf(_player_position.x + _velocity.x * delta, 80.0, VIEW_W - 80.0)

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
	draw_rect(Rect2(Vector2.ZERO, Vector2(VIEW_W, VIEW_H)), Color("#79d5ee"))
	draw_rect(Rect2(0.0, 180.0, VIEW_W, VIEW_H - 180.0), Color("#147fa4"))
	for i in range(22):
		var y := 210.0 + float(i) * 28.0 + sin(Time.get_ticks_msec() / 450.0 + i) * 4.0
		draw_rect(Rect2(0.0, y, VIEW_W, 5.0), Color(0.70, 0.95, 1.0, 0.22))
	draw_rect(Rect2(0.0, 520.0, VIEW_W, 22.0), Color("#e0bd77"))
	draw_rect(Rect2(0.0, 542.0, VIEW_W, 12.0), Color("#8c5429"))


func _draw_dock() -> void:
	draw_rect(Rect2(0.0, 554.0, VIEW_W, VIEW_H - 554.0), Color("#7d4b28"))
	for x in range(0, int(VIEW_W), 88):
		draw_rect(Rect2(float(x), 554.0, 68.0, VIEW_H - 554.0), Color("#a46535"))
		draw_rect(Rect2(float(x) + 68.0, 554.0, 6.0, VIEW_H - 554.0), Color("#503018"))
	for x in range(60, int(VIEW_W), 180):
		draw_rect(Rect2(float(x), 510.0, 18.0, 210.0), Color("#533018"))
		draw_rect(Rect2(float(x) - 6.0, 498.0, 30.0, 14.0), Color("#332012"))


func _draw_boats() -> void:
	for boat in _boats:
		var x: float = boat.x
		var active := int(boat.id) == _active_boat
		var hull_color := Color("#f4a261") if active else Color("#7a3f24")
		draw_rect(Rect2(x - 70.0, 430.0, 140.0, 30.0), hull_color)
		draw_rect(Rect2(x - 54.0, 398.0, 108.0, 38.0), Color("#b45f2b"))
		draw_rect(Rect2(x - 36.0, 362.0, 72.0, 48.0), Color("#e8c37a"))
		draw_rect(Rect2(x - 4.0, 292.0, 8.0, 88.0), Color("#4d2d18"))
		var sail_color := Color("#f4e4bc") if int(boat.id) == 2 else Color("#d94f3d")
		draw_polygon(
			PackedVector2Array([Vector2(x + 6.0, 300.0), Vector2(x + 68.0, 334.0), Vector2(x + 6.0, 368.0)]),
			PackedColorArray([sail_color, sail_color, sail_color])
		)
		draw_string(ThemeDB.fallback_font, Vector2(x - 48.0, 488.0), str(boat.title), HORIZONTAL_ALIGNMENT_LEFT, 120.0, 20, Color.WHITE)
		draw_string(ThemeDB.fallback_font, Vector2(x - 38.0, 512.0), str(boat.status), HORIZONTAL_ALIGNMENT_LEFT, 100.0, 16, Color("#f4e4bc"))


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

	_active_boat = closest if closest_distance <= 88.0 else -1
	if not is_instance_valid(mensaje):
		return
	if _active_boat == 2:
		mensaje.text = "Barco 2: pulsa OK para entrar al minijuego 2."
	elif _active_boat == 1:
		mensaje.text = "Barco 1: minijuego 1 pendiente."
	elif _active_boat == 3:
		mensaje.text = "Barco 3: pulsa OK para entrar a Flappy Pescador."
	else:
		mensaje.text = "Camina al barco 2 y pulsa OK para entrar al minijuego 2."


func _interact() -> void:
	if _active_boat == 2 and not ruta_minijuego_2.is_empty():
		get_tree().change_scene_to_file(ruta_minijuego_2)
	elif _active_boat == 3 and not ruta_minijuego_3.is_empty():
		get_tree().change_scene_to_file(ruta_minijuego_3)
	elif is_instance_valid(mensaje):
		mensaje.text = "Ese barco aun no tiene minijuego conectado."


func _spawn_controls() -> void:
	var scene := preload("res://escenas/controles_moviles/controles_moviles.tscn")
	_controles = scene.instantiate()
	_controles.show_interact = true
	_controles.interact_label = "OK"
	_controles.interact_pressed.connect(_interact)
	var layer := CanvasLayer.new()
	layer.name = "ControlesLobby"
	layer.layer = 10
	layer.add_child(_controles)
	add_child(layer)
