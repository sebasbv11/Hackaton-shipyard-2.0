extends Node2D

const SPEED: float = 340.0
const LIMITE_IZQ: float = 100.0
const LIMITE_DER: float = 1180.0

var puede_moverse: bool = true

func _physics_process(delta: float) -> void:
	if not puede_moverse:
		return
		
	var direccion: float = 0.0
	
	if Input.is_action_pressed("ui_left"):
		direccion = -1.0
	elif Input.is_action_pressed("ui_right"):
		direccion = 1.0
		
	position.x += direccion * SPEED * delta
	position.x = clamp(position.x, LIMITE_IZQ, LIMITE_DER)

func marear_barco() -> void:
	if not puede_moverse:
		return
	puede_moverse = false
	
	# Efecto visual de parpadeo/mareo (tinte rojizo o amarillo)
	var tw = create_tween()
	tw.tween_property(self, "modulate", Color(1, 0.4, 0.4), 0.2)
	tw.tween_property(self, "modulate", Color(1, 1, 1), 0.2)
	tw.tween_property(self, "modulate", Color(1, 0.4, 0.4), 0.2)
	tw.tween_property(self, "modulate", Color(1, 1, 1), 0.2)
	
	# Espera 1.2 segundos y le devuelve el control al jugador
	await get_tree().create_timer(1.2).timeout
	puede_moverse = true
