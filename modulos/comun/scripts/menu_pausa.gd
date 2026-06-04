extends Node

const RUTA_LOBBY := "res://modulos/lobby/escenas/lobby.tscn"
const RUTAS_EXCLUIDAS := [
	"res://modulos/lobby/",
	"res://modulos/menu_principal/",
]

var capa: CanvasLayer
var boton_pausa: Button
var panel: Panel
var titulo: Label
var boton_continuar: Button
var boton_lobby: Button
var ruta_actual := ""
var pausa_abierta := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_crear_interfaz()
	_actualizar_visibilidad()


func _process(_delta: float) -> void:
	var escena := get_tree().current_scene
	var nueva_ruta := escena.scene_file_path if escena else ""
	if nueva_ruta != ruta_actual:
		ruta_actual = nueva_ruta
		if not _escena_permite_pausa():
			_cerrar_pausa(false)
		_actualizar_visibilidad()


func _input(event: InputEvent) -> void:
	if not _escena_permite_pausa():
		return
	if event.is_action_pressed("pausa") or event.is_action_pressed("pause_game") or event.is_action_pressed("ui_cancel"):
		_toggle_pausa()
		get_viewport().set_input_as_handled()


func _crear_interfaz() -> void:
	capa = CanvasLayer.new()
	capa.layer = 100
	add_child(capa)

	boton_pausa = Button.new()
	boton_pausa.text = "II"
	boton_pausa.anchor_left = 1.0
	boton_pausa.anchor_right = 1.0
	boton_pausa.offset_left = -100.0
	boton_pausa.offset_top = 24.0
	boton_pausa.offset_right = -24.0
	boton_pausa.offset_bottom = 88.0
	boton_pausa.focus_mode = Control.FOCUS_NONE
	boton_pausa.add_theme_font_size_override("font_size", 24)
	boton_pausa.pressed.connect(_toggle_pausa)
	capa.add_child(boton_pausa)

	panel = Panel.new()
	panel.visible = false
	panel.anchor_left = 0.5
	panel.anchor_top = 0.5
	panel.anchor_right = 0.5
	panel.anchor_bottom = 0.5
	panel.offset_left = -290.0
	panel.offset_top = -215.0
	panel.offset_right = 290.0
	panel.offset_bottom = 215.0
	panel.process_mode = Node.PROCESS_MODE_ALWAYS
	capa.add_child(panel)

	var fondo := ColorRect.new()
	fondo.color = Color(0.02, 0.05, 0.12, 0.92)
	fondo.anchor_right = 1.0
	fondo.anchor_bottom = 1.0
	panel.add_child(fondo)

	var caja := VBoxContainer.new()
	caja.position = Vector2(50, 46)
	caja.size = Vector2(480, 340)
	caja.add_theme_constant_override("separation", 28)
	panel.add_child(caja)

	titulo = Label.new()
	titulo.text = "Pausa"
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titulo.add_theme_font_size_override("font_size", 46)
	titulo.add_theme_color_override("font_color", Color(1.0, 0.84, 0.38))
	caja.add_child(titulo)

	var texto := Label.new()
	texto.text = "Elige como continuar."
	texto.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	texto.add_theme_font_size_override("font_size", 22)
	texto.add_theme_color_override("font_color", Color(0.86, 0.92, 1.0))
	caja.add_child(texto)

	boton_continuar = _crear_boton("Continuar")
	boton_continuar.pressed.connect(func(): _cerrar_pausa(true))
	caja.add_child(boton_continuar)

	boton_lobby = _crear_boton("Lobby")
	boton_lobby.pressed.connect(_volver_al_lobby)
	caja.add_child(boton_lobby)


func _crear_boton(texto: String) -> Button:
	var boton := Button.new()
	boton.text = texto
	boton.custom_minimum_size = Vector2(420, 72)
	boton.focus_mode = Control.FOCUS_NONE
	boton.add_theme_font_size_override("font_size", 28)
	return boton


func _toggle_pausa() -> void:
	if pausa_abierta:
		_cerrar_pausa(true)
	else:
		_abrir_pausa()


func _abrir_pausa() -> void:
	if not _escena_permite_pausa():
		return
	pausa_abierta = true
	panel.visible = true
	boton_pausa.visible = false
	get_tree().paused = true


func _cerrar_pausa(mantener_escena: bool) -> void:
	pausa_abierta = false
	panel.visible = false
	get_tree().paused = false
	if mantener_escena:
		_actualizar_visibilidad()


func _volver_al_lobby() -> void:
	_cerrar_pausa(false)
	get_tree().change_scene_to_file(RUTA_LOBBY)


func _actualizar_visibilidad() -> void:
	var visible := _escena_permite_pausa() and not pausa_abierta
	if boton_pausa:
		boton_pausa.visible = visible
	if capa:
		capa.visible = _escena_permite_pausa()


func _escena_permite_pausa() -> bool:
	if ruta_actual.is_empty():
		return false
	if not ruta_actual.contains("/minijuego_"):
		return false
	for ruta in RUTAS_EXCLUIDAS:
		if ruta_actual.begins_with(ruta):
			return false
	return true
