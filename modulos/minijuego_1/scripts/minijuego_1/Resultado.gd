extends Node2D

const RUTA_LOBBY := "res://modulos/lobby/escenas/lobby.tscn"

@onready var titulo: Label = $TituloLabel
@onready var puntaje: Label = $PuntajeLabel
@onready var mensaje: Label = $MensajeLabel
@onready var boton: Button = $BotonReiniciar
@onready var fade_overlay: ColorRect = $FadeOverlay
@onready var estrellas: Node2D = $Estrellas


func _ready() -> void:
	fade_overlay.modulate.a = 1.0
	var tw := create_tween()
	tw.tween_property(fade_overlay, "modulate:a", 0.0, 1.2)
	await tw.finished

	titulo.text = "Juego completado!"
	puntaje.text = "Minijuegos completados: 3/3"
	mensaje.text = "La ruta de Manta esta completa.\nEl muelle, la pesca y el mar celebran tu travesia."
	boton.text = "Fin"
	_animar_estrellas(150)


func _mensaje(s: int) -> String:
	if s >= 150:
		return "Eres el mejor pescador de Manta!\nManta - Capital Mundial del Atun"
	elif s >= 80:
		return "Buena faena, navegante!\nEl mar de Manta te recibe con honor."
	elif s >= 30:
		return "La temporada de pesca continua!\nVuelve al mar y lleva la bendicion."
	return "El anzuelo sagrado necesita mas practica.\nIntentalo de nuevo, pescador!"


func _animar_estrellas(s: int) -> void:
	var num := 1
	if s >= 80:
		num = 2
	if s >= 150:
		num = 3
	for star in estrellas.get_children():
		star.visible = false
	for i in num:
		if i < estrellas.get_child_count():
			var star := estrellas.get_child(i)
			star.visible = true
			var tw := create_tween()
			tw.tween_property(star, "scale", Vector2(1.3, 1.3), 0.2)
			tw.tween_property(star, "scale", Vector2(1.0, 1.0), 0.15)
			await get_tree().create_timer(0.2).timeout


func _reiniciar() -> void:
	boton.disabled = true
	if has_node("/root/ControladorGlobal"):
		ControladorGlobal.reiniciar_progreso_minijuegos()
	GameManager.reset()
	get_tree().change_scene_to_file(RUTA_LOBBY)
