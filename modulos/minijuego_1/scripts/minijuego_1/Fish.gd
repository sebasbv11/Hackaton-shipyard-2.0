extends Area2D

@export var tipo_pez: String = "atun"
@export var velocidad: float = 88.0
@export var amplitud: float  = 26.0

var base_y: float  = 0.0
var tiempo: float  = 0.0

func _ready() -> void:
	add_to_group(tipo_pez)
	base_y = position.y
	tiempo = randf() * TAU

func _process(delta: float) -> void:
	position.x -= velocidad * delta
	tiempo += delta * 2.2
	position.y = base_y + sin(tiempo) * amplitud
	rotation = sin(tiempo) * 0.15
	if position.x < -150.0:
		queue_free()
