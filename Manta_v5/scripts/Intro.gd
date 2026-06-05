extends Node2D

# ══════════════════════════════════════════════════════
#  Intro.gd  —  Pantalla de la Diosa Umiña
#  Diálogo animado letra por letra antes de la Fase 1
# ══════════════════════════════════════════════════════

@onready var dialogo_label: RichTextLabel = $PanelDialogo/DialogoLabel
@onready var nombre_label: Label          = $PanelDialogo/NombreLabel
@onready var continuar_label: Label       = $PanelDialogo/ContinuarLabel
@onready var fade_overlay: ColorRect      = $FadeOverlay

const LINEAS := [
	"Joven navegante... el mar te llama.",
	"La temporada de pesca está en peligro.\nLos dioses del océano están inquietos.",
	"Lleva este anzuelo sagrado de concha\nSpondylus desde los cerros hasta el puerto.",
	"Salta sobre las Sillas de Piedra Manteñas,\nrecoge las conchas del camino.",
	"¡Salva la temporada de pesca de Manta!\n¡El pueblo confía en ti, navegante!"
]

var linea_actual: int = 0
var escribiendo: bool = false
var puede_continuar: bool = false
var tween_parpadeo: Tween # Variable para controlar y limpiar el parpadeo

func _ready() -> void:
	fade_overlay.modulate.a = 1.0
	continuar_label.modulate.a = 0.0
	nombre_label.text = "✦ Diosa Umiña ✦"
	dialogo_label.text = ""
	var tw = create_tween()
	tw.tween_property(fade_overlay, "modulate:a", 0.0, 1.0)
	await tw.finished
	await get_tree().create_timer(0.4).timeout
	_mostrar_linea()

func _mostrar_linea() -> void:
	# Si ya habías iniciado un parpadeo previo, lo detenemos para que no deje errores
	if tween_parpadeo:
		tween_parpadeo.kill()
		
	if linea_actual >= LINEAS.size():
		_ir_a_fase_uno()
		return
		
	escribiendo = true
	puede_continuar = false
	continuar_label.modulate.a = 0.0
	dialogo_label.text = ""
	
	var texto = LINEAS[linea_actual]
	for i in texto.length():
		# Estructura de seguridad por si el jugador salta el texto a la mitad
		if not escribiendo: 
			break
		dialogo_label.text += texto[i]
		await get_tree().create_timer(0.03).timeout
		
	escribiendo = false
	puede_continuar = true
	
	# Parpadeo seguro del "Presiona ESPACIO"
	continuar_label.modulate.a = 1.0
	tween_parpadeo = create_tween().set_loops()
	tween_parpadeo.tween_property(continuar_label, "modulate:a", 1.0, 0.4)
	tween_parpadeo.tween_property(continuar_label, "modulate:a", 0.2, 0.4)

# SOLUCIÓN AL BUG: Filtramos para verificar que el evento sea de teclado o botón de acción
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		# Evitamos que el evento se propague a otros nodos duplicando clics
		get_viewport().set_input_as_handled() 
		
		if escribiendo:
			# Mostrar texto completo inmediatamente
			escribiendo = false
			dialogo_label.text = LINEAS[linea_actual]
			puede_continuar = true
			
			# Activamos el parpadeo del botón continuar inmediatamente
			if tween_parpadeo: tween_parpadeo.kill()
			continuar_label.modulate.a = 1.0
			tween_parpadeo = create_tween().set_loops()
			tween_parpadeo.tween_property(continuar_label, "modulate:a", 1.0, 0.4)
			tween_parpadeo.tween_property(continuar_label, "modulate:a", 0.2, 0.4)
		elif puede_continuar:
			linea_actual += 1
			_mostrar_linea()

func _ir_a_fase_uno() -> void:
	if tween_parpadeo:
		tween_parpadeo.kill()
	var tw = create_tween()
	tw.tween_property(fade_overlay, "modulate:a", 1.0, 1.0)
	await tw.finished
	get_tree().change_scene_to_file("res://scenes/fase_uno.tscn")
