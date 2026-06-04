extends Node2D

@onready var puntaje_label: Label     = $PuntajeLabel
@onready var boton_reiniciar: Button  = $BotonReiniciar
@onready var fade_overlay: ColorRect  = $FadeOverlay

func _ready() -> void:
	fade_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade_overlay.modulate.a = 1.0
	var tw = create_tween()
	tw.tween_property(fade_overlay, "modulate:a", 0.0, 1.0)
	await tw.finished
	puntaje_label.text = "Conchas recolectadas: %d" % GameManager.score
	boton_reiniciar.pressed.connect(_reiniciar)
	
	
func _reiniciar() -> void:
	boton_reiniciar.disabled = true
	GameManager.reset()
	var tw = create_tween()
	tw.tween_property(fade_overlay, "modulate:a", 1.0, 0.7)
	await tw.finished
	get_tree().change_scene_to_file("res://modulos/minijuego_1/escenas/minijuego_1/intro.tscn")
