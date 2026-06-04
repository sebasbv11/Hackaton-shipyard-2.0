extends Node2D

@export var niveles: Array[PackedScene]
@export var controlador_partida: ControladorPartida

var _nivel_actual: int = 1
var _nivel_instanciado: Node


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if ControladorGlobal.nivel > 1:
		_cargar_nivel()
	else:
		_crear_nivel(_nivel_actual)


func _crear_nivel(numero_nivel: int):
	if niveles.is_empty():
		push_error("No hay niveles configurados en EscenaPrincipal.")
		return

	numero_nivel = clampi(numero_nivel, 1, niveles.size())
	_nivel_actual = numero_nivel
	_nivel_instanciado = niveles[numero_nivel - 1].instantiate()
	add_child(_nivel_instanciado)
	
	var hijos := _nivel_instanciado.get_children()
	for i in hijos.size():
		if hijos[i].is_in_group("personajes"):
			hijos[i].personaje_muerto.connect(_reiniciar_nivel)
			break
	
	ControladorGlobal.nivel = numero_nivel
	controlador_partida.guardar_partida()


func _eliminar_nivel():
	if is_instance_valid(_nivel_instanciado):
		_nivel_instanciado.queue_free()


func _reiniciar_nivel():
	_eliminar_nivel()
	_crear_nivel.call_deferred(_nivel_actual)


func siguiente_nivel():
	if _nivel_actual >= niveles.size():
		return

	_nivel_actual += 1
	_eliminar_nivel()
	_crear_nivel.call_deferred(_nivel_actual)


func _cargar_nivel():
	_nivel_actual = ControladorGlobal.nivel
	_crear_nivel.call_deferred(_nivel_actual)
