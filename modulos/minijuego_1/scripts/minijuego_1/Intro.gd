extends Node2D

@onready var dialogo_label: RichTextLabel = $PanelDialogo/DialogoLabel
@onready var nombre_label: Label = $PanelDialogo/NombreLabel
@onready var continuar_label: Label = $PanelDialogo/ContinuarLabel
@onready var fade_overlay: ColorRect = $FadeOverlay

const LINEAS := [
	"Joven navegante... el mar te llama.",
	"La temporada de pesca esta en peligro.\nLos dioses del oceano estan inquietos.",
	"Lleva este anzuelo sagrado de concha\nSpondylus desde los cerros hasta el puerto.",
	"Salta sobre las Sillas de Piedra Mantenas,\nrecoge las conchas del camino.",
	"Salva la temporada de pesca de Manta!\nEl pueblo confia en ti, navegante!"
]

var linea_actual: int = 0
var escribiendo: bool = false
var puede_continuar: bool = false
var tween_parpadeo: Tween


func _ready() -> void:
	fade_overlay.modulate.a = 1.0
	continuar_label.modulate.a = 0.0
	nombre_label.text = "Diosa Umina"
	dialogo_label.text = ""
	var tw := create_tween()
	tw.tween_property(fade_overlay, "modulate:a", 0.0, 1.0)
	await tw.finished
	await get_tree().create_timer(0.4).timeout
	_mostrar_linea()


func _mostrar_linea() -> void:
	if tween_parpadeo:
		tween_parpadeo.kill()

	if linea_actual >= LINEAS.size():
		_ir_a_fase_uno()
		return

	escribiendo = true
	puede_continuar = false
	continuar_label.modulate.a = 0.0
	dialogo_label.text = ""

	var texto: String = LINEAS[linea_actual]
	for i in texto.length():
		if not escribiendo:
			break
		dialogo_label.text += texto[i]
		await get_tree().create_timer(0.03).timeout

	escribiendo = false
	puede_continuar = true
	_activar_indicador_continuar()


func _input(event: InputEvent) -> void:
	var avanzar := event.is_action_pressed("ui_accept")
	if event is InputEventScreenTouch:
		avanzar = (event as InputEventScreenTouch).pressed
	elif event is InputEventMouseButton:
		var mouse := event as InputEventMouseButton
		avanzar = mouse.pressed and mouse.button_index == MOUSE_BUTTON_LEFT

	if avanzar:
		get_viewport().set_input_as_handled()
		_avanzar_dialogo()


func _avanzar_dialogo() -> void:
	if escribiendo:
		escribiendo = false
		dialogo_label.text = LINEAS[linea_actual]
		puede_continuar = true
		_activar_indicador_continuar()
	elif puede_continuar:
		linea_actual += 1
		_mostrar_linea()


func _activar_indicador_continuar() -> void:
	if tween_parpadeo:
		tween_parpadeo.kill()
	continuar_label.modulate.a = 1.0
	tween_parpadeo = create_tween().set_loops()
	tween_parpadeo.tween_property(continuar_label, "modulate:a", 1.0, 0.4)
	tween_parpadeo.tween_property(continuar_label, "modulate:a", 0.2, 0.4)


func _ir_a_fase_uno() -> void:
	if tween_parpadeo:
		tween_parpadeo.kill()
	var tw := create_tween()
	tw.tween_property(fade_overlay, "modulate:a", 1.0, 1.0)
	await tw.finished
	get_tree().change_scene_to_file("res://modulos/minijuego_1/escenas/minijuego_1/fase_uno.tscn")
