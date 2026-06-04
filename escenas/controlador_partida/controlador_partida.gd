class_name ControladorPartida
extends Node

var _ruta: String = "user://partida.cfg"


func guardar_partida():
	var archivo := ConfigFile.new()
	archivo.set_value("partida", "nivel", ControladorGlobal.nivel)
	archivo.set_value("partida", "muertes", ControladorGlobal.muertes)

	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("user://"))
	var resultado := archivo.save(_ruta)
	if resultado != OK:
		push_warning("No se pudo guardar la partida en %s. Codigo: %s" % [_ruta, resultado])


func cargar_partida():
	var archivo := ConfigFile.new()
	var resultado := archivo.load(_ruta)
	if resultado != OK:
		return

	ControladorGlobal.nivel = int(archivo.get_value("partida", "nivel", 1))
	ControladorGlobal.muertes = int(archivo.get_value("partida", "muertes", 0))
