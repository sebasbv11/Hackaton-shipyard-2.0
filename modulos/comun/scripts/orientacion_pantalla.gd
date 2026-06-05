extends Node

const ESCENAS_VERTICALES := [
	"res://modulos/menu_principal/",
]
const ESCENAS_HORIZONTALES := [
	"res://modulos/lobby/",
	"res://modulos/minijuego_1/",
	"res://modulos/minijuego_3_plataforma/",
	"res://modulos/minijuego_4_flappy/",
]
const ESCENA_RESULTADO := "res://modulos/minijuego_1/escenas/minijuego_1/resultado.tscn"
const TAMANO_VERTICAL := Vector2i(720, 1280)
const TAMANO_HORIZONTAL := Vector2i(1280, 720)

var _ruta_actual := ""
var _requiere_horizontal := false
var _capa_aviso: CanvasLayer
var _panel_aviso: Panel


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_crear_aviso_giro()
	_actualizar_orientacion()


func _process(_delta: float) -> void:
	_actualizar_orientacion()
	_actualizar_aviso_giro()


func _actualizar_orientacion() -> void:
	var escena := get_tree().current_scene
	var ruta := escena.scene_file_path if escena != null else ""
	if ruta == _ruta_actual:
		return

	_ruta_actual = ruta
	_requiere_horizontal = _es_horizontal(ruta)
	get_window().content_scale_size = TAMANO_HORIZONTAL if _requiere_horizontal else TAMANO_VERTICAL
	if _es_dispositivo_movil():
		if _requiere_horizontal:
			DisplayServer.screen_set_orientation(DisplayServer.SCREEN_SENSOR_LANDSCAPE)
		else:
			DisplayServer.screen_set_orientation(DisplayServer.SCREEN_SENSOR_PORTRAIT)


func _es_horizontal(ruta: String) -> bool:
	if ruta == ESCENA_RESULTADO:
		return true
	for prefijo in ESCENAS_HORIZONTALES:
		if ruta.begins_with(prefijo):
			return true
	for prefijo in ESCENAS_VERTICALES:
		if ruta.begins_with(prefijo):
			return false
	return false


func _crear_aviso_giro() -> void:
	_capa_aviso = CanvasLayer.new()
	_capa_aviso.layer = 200
	add_child(_capa_aviso)

	_panel_aviso = Panel.new()
	_panel_aviso.visible = false
	_panel_aviso.anchor_left = 0.0
	_panel_aviso.anchor_top = 0.0
	_panel_aviso.anchor_right = 1.0
	_panel_aviso.anchor_bottom = 1.0
	_panel_aviso.process_mode = Node.PROCESS_MODE_ALWAYS
	_capa_aviso.add_child(_panel_aviso)

	var fondo := ColorRect.new()
	fondo.color = Color(0.02, 0.05, 0.10, 0.92)
	fondo.anchor_right = 1.0
	fondo.anchor_bottom = 1.0
	_panel_aviso.add_child(fondo)

	var caja := VBoxContainer.new()
	caja.anchor_left = 0.5
	caja.anchor_top = 0.5
	caja.anchor_right = 0.5
	caja.anchor_bottom = 0.5
	caja.offset_left = -300.0
	caja.offset_top = -130.0
	caja.offset_right = 300.0
	caja.offset_bottom = 130.0
	caja.add_theme_constant_override("separation", 22)
	_panel_aviso.add_child(caja)

	var icono := Label.new()
	icono.text = "<->"
	icono.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icono.add_theme_font_size_override("font_size", 66)
	icono.add_theme_color_override("font_color", Color(1.0, 0.84, 0.38))
	caja.add_child(icono)

	var titulo := Label.new()
	titulo.text = "Gira tu celular"
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titulo.add_theme_font_size_override("font_size", 42)
	titulo.add_theme_color_override("font_color", Color.WHITE)
	caja.add_child(titulo)

	var detalle := Label.new()
	detalle.text = "Este minijuego se juega en horizontal."
	detalle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	detalle.add_theme_font_size_override("font_size", 24)
	detalle.add_theme_color_override("font_color", Color(0.82, 0.90, 1.0))
	caja.add_child(detalle)


func _actualizar_aviso_giro() -> void:
	if _panel_aviso == null:
		return
	if not _es_dispositivo_movil():
		_panel_aviso.visible = false
		return
	var tamano := get_viewport().get_visible_rect().size
	_panel_aviso.visible = _requiere_horizontal and tamano.y > tamano.x


func _es_dispositivo_movil() -> bool:
	return OS.has_feature("mobile") or OS.has_feature("android") or OS.has_feature("ios")
