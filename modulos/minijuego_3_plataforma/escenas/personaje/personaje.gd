extends CharacterBody2D

signal personaje_muerto

@export var animacion: AnimatedSprite2D
@export var area_2d: Area2D
@export var material_personaje_rojo: ShaderMaterial

var _velocidad: float = 100.0
var _velocidad_salto: float = -300.0
var _muerto: bool


func _ready() -> void:
	add_to_group("personajes")
	area_2d.body_entered.connect(_on_area_2d_body_entered)


func _physics_process(delta: float) -> void:
	if _muerto:
		return

	velocity += get_gravity() * delta

	if Input.is_action_just_pressed("saltar") and is_on_floor():
		velocity.y = _velocidad_salto

	if Input.is_action_pressed("derecha"):
		velocity.x = _velocidad
		animacion.flip_h = false
	elif Input.is_action_pressed("izquierda"):
		velocity.x = -_velocidad
		animacion.flip_h = true
	else:
		velocity.x = 0

	move_and_slide()

	if not is_on_floor():
		animacion.play("saltar")
	elif velocity.x != 0:
		animacion.play("correr")
	else:
		animacion.play("idle")


func _on_area_2d_body_entered(_body: Node2D) -> void:
	animacion.material = material_personaje_rojo
	_muerto = true
	animacion.stop()

	await get_tree().create_timer(0.5).timeout
	personaje_muerto.emit()
	ControladorGlobal.sumar_muerte()
