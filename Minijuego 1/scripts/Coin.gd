extends Area2D

# Gema sagrada — al recolectar 5 en la zona se avanza
var float_time: float = 0.0
var base_y: float = 0.0
var recogida: bool = false

func _ready() -> void:
	base_y = position.y
	float_time = randf() * TAU
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)

func _process(delta: float) -> void:
	float_time += delta * 3.0
	position.y = base_y + sin(float_time) * 9.0
	rotation += delta * 1.5

func _on_body_entered(body: Node) -> void:
	if body.name == "Player" or body.is_in_group("player"):
		_recolectar()

func _on_area_entered(area: Area2D) -> void:
	if area.name == "CoinCollector":
		_recolectar()

func _recolectar() -> void:
	if recogida:
		return
	recogida = true
	GameManager.recolectar_gema()
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)
	var tw = create_tween()
	tw.tween_property(self, "scale", Vector2(2.2, 2.2), 0.14)
	tw.tween_property(self, "modulate:a", 0.0, 0.14)
	await tw.finished
	queue_free()
