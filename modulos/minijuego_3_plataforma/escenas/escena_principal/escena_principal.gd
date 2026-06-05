extends Node2D

const RUTA_LOBBY := "res://modulos/lobby/escenas/lobby.tscn"
const SEGUNDOS_FINAL := 5.0

@export var niveles: Array[PackedScene]
@export var controlador_partida: ControladorPartida

var _nivel_actual: int = 1
var _nivel_instanciado: Node
var _volviendo_al_lobby := false


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	ControladorGlobal.nivel = 1
	_crear_nivel(_nivel_actual)


func _crear_nivel(numero_nivel: int):
	if niveles.is_empty():
		push_error("No hay niveles configurados en EscenaPrincipal.")
		return

	numero_nivel = clampi(numero_nivel, 1, niveles.size())
	_nivel_actual = numero_nivel
	_nivel_instanciado = niveles[numero_nivel - 1].instantiate()
	add_child(_nivel_instanciado)

	if _es_escena_final(_nivel_instanciado):
		_volver_al_lobby_luego()
		return
	
	var hijos := _nivel_instanciado.get_children()
	for i in hijos.size():
		if hijos[i].is_in_group("personajes"):
			hijos[i].personaje_muerto.connect(_reiniciar_nivel)
			break
	
	ControladorGlobal.nivel = numero_nivel


func _eliminar_nivel():
	if is_instance_valid(_nivel_instanciado):
		_nivel_instanciado.queue_free()


func _reiniciar_nivel():
	_eliminar_nivel()
	_crear_nivel.call_deferred(_nivel_actual)


func siguiente_nivel():
	if _nivel_actual >= niveles.size() or _volviendo_al_lobby:
		return

	_nivel_actual += 1
	_eliminar_nivel()
	_crear_nivel.call_deferred(_nivel_actual)


func _cargar_nivel():
	_nivel_actual = ControladorGlobal.nivel
	_crear_nivel.call_deferred(_nivel_actual)


func _es_escena_final(nivel: Node) -> bool:
	return nivel.name == "EscenaFinal"


func _volver_al_lobby_luego() -> void:
	if _volviendo_al_lobby:
		return

	_volviendo_al_lobby = true
	await get_tree().create_timer(SEGUNDOS_FINAL).timeout
	if not is_inside_tree():
		return

	ControladorGlobal.nivel = 1
	ControladorGlobal.muertes = 0
	var destino := ControladorGlobal.obtener_destino_tras_completar(2, RUTA_LOBBY)
	get_tree().change_scene_to_file(destino)
