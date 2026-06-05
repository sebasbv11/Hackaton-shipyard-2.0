extends Node

signal muertes_actualizado
signal minijuego_completado(id_minijuego)

const RUTA_RESULTADO_FINAL := "res://modulos/minijuego_1/escenas/minijuego_1/resultado.tscn"
const TOTAL_MINIJUEGOS := 3

var nivel: int = 1
var muertes: int = 0
var minijuegos_completados := {
	1: false,
	2: false,
	3: false,
}
var resultado_final_mostrado := false


func sumar_muerte():
	muertes += 1
	muertes_actualizado.emit()


func reiniciar_progreso_minijuegos() -> void:
	for id in minijuegos_completados.keys():
		minijuegos_completados[id] = false
	resultado_final_mostrado = false
	nivel = 1
	muertes = 0
	muertes_actualizado.emit()


func marcar_minijuego_completado(id_minijuego: int) -> void:
	if not minijuegos_completados.has(id_minijuego):
		return
	if bool(minijuegos_completados[id_minijuego]):
		return

	minijuegos_completados[id_minijuego] = true
	minijuego_completado.emit(id_minijuego)


func obtener_destino_tras_completar(id_minijuego: int, ruta_lobby: String) -> String:
	marcar_minijuego_completado(id_minijuego)
	if _todos_los_minijuegos_completados() and not resultado_final_mostrado:
		resultado_final_mostrado = true
		return RUTA_RESULTADO_FINAL
	return ruta_lobby


func _todos_los_minijuegos_completados() -> bool:
	for completado in minijuegos_completados.values():
		if not bool(completado):
			return false
	return minijuegos_completados.size() == TOTAL_MINIJUEGOS
