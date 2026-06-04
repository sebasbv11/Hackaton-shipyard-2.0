extends Node2D

const PROFUNDIDAD: float = 460.0
const VELOCIDAD_BAJAR: float = 0.75
const VELOCIDAD_SUBIR_BASE: float = 0.75

var lanzando: bool = false
var inicio_y: float = 0.0
var area_real: Area2D
var velocidad_retorno_actual: float = 0.75

func _ready() -> void:
	inicio_y = position.y
	
	area_real = get_node_or_null("DetectorAnzuelo")
	if not area_real:
		area_real = Area2D.new()
		area_real.name = "DetectorAnzuelo"
		add_child(area_real)
		
		var colisionador = CollisionShape2D.new()
		var forma_circulo = CircleShape2D.new()
		forma_circulo.radius = 22.0
		colisionador.shape = forma_circulo
		area_real.add_child(colisionador)
	
	if not area_real.area_entered.is_connected(_on_area_entered):
		area_real.area_entered.connect(_on_area_entered)

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("ui_accept") and not lanzando:
		_lanzar()

func _lanzar() -> void:
	lanzando = true
	velocidad_retorno_actual = VELOCIDAD_SUBIR_BASE
	
	# 🌊 EFECTO: Salpicadura al entrar al agua
	var fase_principal = get_parent().get_parent() # Barco -> Escena Fase2
	if fase_principal.has_method("crear_salpicadura"):
		fase_principal.crear_salpicadura(global_position.x)
	
	var tw = create_tween()
	
	# Bajar normal
	tw.tween_property(self, "position:y", inicio_y + PROFUNDIDAD, VELOCIDAD_BAJAR)\
		.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_SINE)
		
	tw.tween_interval(0.08)
	
	# Subir usando la velocidad modificada
	tw.tween_method(func(val): position.y = val, inicio_y + PROFUNDIDAD, inicio_y, velocidad_retorno_actual)\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
		
	await tw.finished
	
	# 🌊 EFECTO: Salpicadura al salir del agua con el pez
	if fase_principal.has_method("crear_salpicadura"):
		fase_principal.crear_salpicadura(global_position.x)
		
	lanzando = false


func _on_area_entered(area: Area2D) -> void:
	if area.is_queued_for_deletion() or not area.is_inside_tree():
		return
		
	if area.is_in_group("atun"):
		GameManager.add_score(10)
		velocidad_retorno_actual = VELOCIDAD_SUBIR_BASE * 1.4 # Sube un poco más lento (peso mediano)
		_efecto_captura(area, Color(0.2, 0.8, 1))
		
	elif area.is_in_group("atun_dorado"):
		GameManager.add_score(50) # ¡El Gran Botín!
		velocidad_retorno_actual = VELOCIDAD_SUBIR_BASE * 1.2 # El dorado es rápido, no pesa tanto
		_efecto_captura(area, Color(1.0, 0.85, 0.2)) # Destello dorado brillante
		
	elif area.is_in_group("tortuga"):
		GameManager.add_score(-20)
		velocidad_retorno_actual = VELOCIDAD_SUBIR_BASE * 2.2 # ¡Extremadamente lento! (Muy pesada)
		_efecto_captura(area, Color(1, 0.3, 0.3))

func _efecto_captura(obj: Node, color: Color) -> void:
	if obj.has_method("set_deferred"):
		obj.set_deferred("monitoring", false)
		obj.set_deferred("monitorable", false)
		
	var tw = create_tween()
	tw.tween_property(obj, "modulate", color, 0.08)
	tw.tween_property(obj, "scale", Vector2(1.5, 1.5), 0.08)
	tw.tween_property(obj, "modulate:a", 0.0, 0.15)
	await tw.finished
	
	if is_instance_valid(obj) and not obj.is_queued_for_deletion():
		obj.queue_free()
