extends Node2D

@onready var fishing_timer: Timer = $TemporizadorPesca
@onready var spawn_timer: Timer   = $SpawnPeces
@onready var fade_overlay: ColorRect = $FadeOverlay
@onready var score_label: Label   = $HUD/ScoreLabel
@onready var timer_label: Label   = $HUD/TimerLabel
@onready var barra_tiempo: ProgressBar = $HUD/BarraTiempo

@export var escena_atun: PackedScene
@export var escena_tortuga: PackedScene

const SPAWN_X: float       = 1400.0
const MIN_Y: float         = 470.0
const MAX_Y: float         = 680.0
const PROB_TORTUGA: float  = 0.18
const PROB_ATUN_DORADO: float = 0.08
const DURACION_PESCA: float = 45.0
const RUTA_LOBBY: String = "res://modulos/lobby/escenas/lobby.tscn"

func _ready() -> void:
	var barco = get_node_or_null("Boat")
	
	if barco:
		# Forzamos que tenga asignado el script de movimiento adaptado a Node2D
		barco.set_script(load("res://modulos/minijuego_1/scripts/minijuego_1/Boat.gd"))
		
		var pescador = ColorRect.new()
		pescador.size = Vector2(26, 40)
		pescador.position = Vector2(-13, -35) # Justo encima de la lancha
		pescador.color = Color(0.92, 0.40, 0.13) # Color naranja de la Fase 1
		barco.add_child(pescador)
		
		var cabeza = ColorRect.new()
		cabeza.size = Vector2(20, 20)
		cabeza.position = Vector2(-10, -55)
		cabeza.color = Color(0.78, 0.61, 0.43)
		barco.add_child(cabeza)
		
		var sombrero = ColorRect.new()
		sombrero.size = Vector2(30, 8)
		sombrero.position = Vector2(-15, -63)
		sombrero.color = Color(0.50, 0.35, 0.15)
		barco.add_child(sombrero)
		
		var anzuelo = get_node_or_null("Hook")
		if is_instance_valid(anzuelo) and not anzuelo.is_queued_for_deletion():
			anzuelo.set_script(load("res://modulos/minijuego_1/scripts/minijuego_1/Hook.gd"))
			
			# Hacemos que el anzuelo sea hijo del barco para que lo arrastre horizontalmente
			if anzuelo.get_parent() != barco:
				anzuelo.get_parent().remove_child(anzuelo)
				barco.add_child(anzuelo)
			
			# Lo centramos debajo de tu lancha
			anzuelo.position = Vector2(0, 15)

	if not GameManager.score_changed.is_connected(_on_score_changed):
		GameManager.score_changed.connect(_on_score_changed)
		
	score_label.text = "Atunes: %d" % GameManager.score
	fishing_timer.wait_time = DURACION_PESCA
	barra_tiempo.max_value = DURACION_PESCA
	barra_tiempo.value = DURACION_PESCA
	fade_overlay.modulate.a = 1.0
	
	var tw = create_tween()
	tw.tween_property(fade_overlay, "modulate:a", 0.0, 1.2)
	await tw.finished
	fishing_timer.start()
	spawn_timer.start()

func _process(_delta: float) -> void:
	var t = fishing_timer.time_left
	timer_label.text = "Tiempo: %d" % int(t)
	barra_tiempo.value = t

func _on_score_changed(nuevo: int) -> void:
	score_label.text = "Atunes: %d" % nuevo

func _on_spawn_peces_timeout() -> void:
	var y = randf_range(MIN_Y, MAX_Y)
	
	if randf() < 0.15:
		var tronco = ColorRect.new()
		tronco.size = Vector2(45, 15)
		tronco.position = Vector2(SPAWN_X, 325.0)
		tronco.color = Color(0.45, 0.29, 0.15) # Color madera
		tronco.name = "ObstaculoFlotante"
		add_child(tronco)
		
		# Script de movimiento directo para el tronco de derecha a izquierda
		var tw_mov = create_tween()
		tw_mov.tween_property(tronco, "position:x", -100.0, 4.5)
		
		var area = Area2D.new()
		var col = CollisionShape2D.new()
		var forma = RectangleShape2D.new()
		forma.size = Vector2(45, 15)
		col.shape = forma
		area.add_child(col)
		tronco.add_child(area)
		
		area.area_entered.connect(_on_tronco_choca_con_barco.bind(tronco))
		
		await tw_mov.finished
		if is_instance_valid(tronco):
			tronco.queue_free()
		return # Salimos para que no genere un pez al mismo tiempo
		
	if randf() < PROB_TORTUGA and escena_tortuga != null:
		var t = escena_tortuga.instantiate()
		t.position = Vector2(SPAWN_X, y)
		add_child(t)
	elif randf() < PROB_ATUN_DORADO and escena_atun != null:
		var ad = escena_atun.instantiate()
		ad.position = Vector2(SPAWN_X, y)
		ad.add_to_group("atun_dorado")
		ad.modulate = Color(1.1, 0.9, 0.2)
		if "SPEED" in ad: ad.SPEED = ad.SPEED * 2.0
		elif "velocidad" in ad: ad.velocidad = ad.velocidad * 2.0
		add_child(ad)
	elif escena_atun != null:
		var a = escena_atun.instantiate()
		a.position = Vector2(SPAWN_X, y)
		add_child(a)

func _on_temporizador_pesca_timeout() -> void:
	spawn_timer.stop()
	await get_tree().create_timer(0.8).timeout
	_ir_al_lobby()

func _ir_al_lobby() -> void:
	var tw = create_tween()
	tw.tween_property(fade_overlay, "modulate:a", 1.0, 1.2)
	await tw.finished
	var destino := ControladorGlobal.obtener_destino_tras_completar(1, RUTA_LOBBY)
	get_tree().change_scene_to_file(destino)

func crear_salpicadura(posicion_x: float) -> void:
	var salpicadura = ColorRect.new()
	salpicadura.size = Vector2(10, 6)
	salpicadura.position = Vector2(posicion_x - 5, 330.0)
	salpicadura.color = Color(1, 1, 1, 0.8) # Blanco semitransparente
	add_child(salpicadura)
	
	var tw = create_tween().set_parallel(true)
	tw.tween_property(salpicadura, "scale", Vector2(6.0, 0.5), 0.35)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(salpicadura, "position:x", posicion_x - 30, 0.35)
	tw.tween_property(salpicadura, "modulate:a", 0.0, 0.35)
	
	await get_tree().create_timer(0.4).timeout
	if is_instance_valid(salpicadura):
		salpicadura.queue_free()

func create_timer(tiempo: float) -> SceneTreeTimer:
	return get_tree().create_timer(tiempo)

func _on_tronco_choca_con_barco(otra_area: Area2D, tronco_nodo: ColorRect) -> void:
	var barco = get_node_or_null("Boat")
	if barco and barco.puede_moverse:
		if is_instance_valid(tronco_nodo) and abs(tronco_nodo.global_position.x - barco.global_position.x) < 80:
			barco.marear_barco()
			tronco_nodo.queue_free()
