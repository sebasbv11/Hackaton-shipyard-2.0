extends Node2D

@onready var titulo: Label           = $TituloLabel
@onready var puntaje: Label          = $PuntajeLabel
@onready var mensaje: Label          = $MensajeLabel
@onready var boton: Button           = $BotonReiniciar
@onready var fade_overlay: ColorRect = $FadeOverlay

const FRASES_UMINA = [
	"Noble navegante... lo has logrado.\nEl anzuelo sagrado llego al mar.",
	"Los dioses del oceano estan complacidos.\nManta tendra una gran temporada de pesca.",
	"Llevaste la bendicion desde los cerros\nhasta el puerto con valentia.",
	"El pueblo de Manta te recordara\ncomo el héroe del Descenso Sagrado.",
	"Que las aguas del Pacifico\nsiempre guien tu camino, pescador."
]

var frase_idx: int = 0
var dialogo_umina: Label = null
var canvas: CanvasLayer = null

func _ready() -> void:
	fade_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade_overlay.modulate.a = 1.0
	var tw = create_tween()
	tw.tween_property(fade_overlay, "modulate:a", 0.0, 1.2)
	await tw.finished

	titulo.text = "Mision Cumplida!"
	puntaje.text = "Puntaje final: %d" % GameManager.score
	mensaje.text = _mensaje(GameManager.score)
	boton.disabled = false
	boton.pressed.connect(_reiniciar)

	# Crear panel de Umiña completamente por código
	_crear_panel_umina()
	await get_tree().create_timer(0.8).timeout
	_mostrar_frase_umina()

func _crear_panel_umina() -> void:
	# Fondo del panel
	var fondo = ColorRect.new()
	fondo.position = Vector2(40, 620)
	fondo.size = Vector2(1200, 95)
	fondo.color = Color(0.05, 0.02, 0.18, 0.92)
	fondo.z_index = 0
	fondo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(fondo)

	# Borde superior morado
	var borde = ColorRect.new()
	borde.position = Vector2(40, 618)
	borde.size = Vector2(1200, 3)
	borde.color = Color(0.60, 0.28, 0.95, 1)
	borde.z_index = 0
	borde.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(borde)

	# Nombre
	var nombre = Label.new()
	nombre.text = "Diosa Umina"
	nombre.position = Vector2(60, 624)
	nombre.z_index = 0
	nombre.add_theme_font_size_override("font_size", 15)
	nombre.add_theme_color_override("font_color", Color(0.80, 0.55, 1.0, 1))
	add_child(nombre)

	# Diálogo
	dialogo_umina = Label.new()
	dialogo_umina.position = Vector2(60, 645)
	dialogo_umina.size = Vector2(1160, 65)
	dialogo_umina.autowrap_mode = TextServer.AUTOWRAP_WORD
	dialogo_umina.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	dialogo_umina.z_index = 0
	dialogo_umina.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dialogo_umina.add_theme_font_size_override("font_size", 19)
	dialogo_umina.add_theme_color_override("font_color", Color(0.94, 0.92, 1.0, 1))
	add_child(dialogo_umina)

func _mostrar_frase_umina() -> void:
	if not is_instance_valid(dialogo_umina):
		return
	dialogo_umina.text = ""
	var texto = FRASES_UMINA[frase_idx % FRASES_UMINA.size()]
	for i in texto.length():
		if not is_instance_valid(dialogo_umina):
			return
		dialogo_umina.text += texto[i]
		await get_tree().create_timer(0.032).timeout
	await get_tree().create_timer(3.0).timeout
	frase_idx += 1
	if frase_idx < FRASES_UMINA.size():
		_mostrar_frase_umina()

func _mensaje(s: int) -> String:
	if s >= 200:
		return "Leyenda del mar de Manta!"
	elif s >= 120:
		return "Excelente faena, navegante!"
	elif s >= 50:
		return "La bendicion llego al puerto!"
	else:
		return "El anzuelo sagrado te necesita!"

func _reiniciar() -> void:
	boton.disabled = true
	GameManager.reset()
	var tw = create_tween()
	tw.tween_property(fade_overlay, "modulate:a", 1.0, 1.0)
	await tw.finished
	get_tree().change_scene_to_file("res://scenes/intro.tscn")
