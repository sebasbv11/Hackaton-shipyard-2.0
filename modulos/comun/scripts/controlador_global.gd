extends Node

signal muertes_actualizado

var nivel: int = 1
var muertes: int = 0


func sumar_muerte():
	muertes += 1
	muertes_actualizado.emit()
