extends Node

const RUTA_MUSICA_FONDO := "res://audio/musica_fondo.wav"
const RUTA_MUSICA_BOTE := "res://audio/musica_bote_pesca.wav"
const RUTA_OLAS := "res://audio/sonido_olas_mar.wav"
const RUTA_FASE_DOS := "res://modulos/minijuego_1/escenas/minijuego_1/fase_dos.tscn"

var _music_player: AudioStreamPlayer
var _waves_player: AudioStreamPlayer
var _current_music := ""
var _last_scene_path := ""


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_ensure_audio_buses()
	_music_player = AudioStreamPlayer.new()
	_music_player.name = "MusicaGlobal"
	_set_player_bus(_music_player, &"Musica")
	_music_player.volume_db = -4.0
	add_child(_music_player)

	_waves_player = AudioStreamPlayer.new()
	_waves_player.name = "OlasMar"
	_set_player_bus(_waves_player, &"SFX")
	_waves_player.volume_db = -10.0
	add_child(_waves_player)

	_sync_current_scene()


func _process(_delta: float) -> void:
	_sync_current_scene()
	_keep_loops_running()


func _exit_tree() -> void:
	_stop_music()
	_stop_waves()
	if _music_player != null:
		_music_player.stream = null
	if _waves_player != null:
		_waves_player.stream = null


func _sync_current_scene() -> void:
	var scene := get_tree().current_scene
	var scene_path := scene.scene_file_path if scene != null else ""
	if scene_path == _last_scene_path:
		return

	_last_scene_path = scene_path
	_sync_audio_for_scene(scene_path)


func _sync_audio_for_scene(scene_path: String) -> void:
	if scene_path.begins_with("res://modulos/menu_principal/") or scene_path.begins_with("res://modulos/lobby/") or scene_path.begins_with("res://modulos/minijuego_4_flappy/"):
		_play_music(RUTA_MUSICA_FONDO, -4.0)
		_stop_waves()
	elif scene_path.begins_with("res://modulos/minijuego_1/"):
		_play_music(RUTA_MUSICA_BOTE, -4.0)
		if scene_path == RUTA_FASE_DOS:
			_play_waves()
		else:
			_stop_waves()
	else:
		_stop_music()
		_stop_waves()


func _keep_loops_running() -> void:
	if not _current_music.is_empty() and _music_player.stream != null and not _music_player.playing:
		_music_player.play()
	if _last_scene_path == RUTA_FASE_DOS and _waves_player.stream != null and not _waves_player.playing:
		_waves_player.play()


func _play_music(audio_path: String, volume_db: float) -> void:
	if _current_music == audio_path and _music_player.playing:
		return

	var stream := load(audio_path) as AudioStream
	if stream == null:
		push_warning("No se pudo cargar el audio: %s" % audio_path)
		_stop_music()
		return

	_set_loop(stream)
	_current_music = audio_path
	_music_player.stream = stream
	_music_player.volume_db = volume_db
	_music_player.play()


func _play_waves() -> void:
	if _waves_player.playing:
		return

	var stream := load(RUTA_OLAS) as AudioStream
	if stream == null:
		push_warning("No se pudo cargar el audio: %s" % RUTA_OLAS)
		return

	_set_loop(stream)
	_waves_player.stream = stream
	_waves_player.play()


func _stop_music() -> void:
	_current_music = ""
	if _music_player.playing:
		_music_player.stop()


func _stop_waves() -> void:
	if _waves_player.playing:
		_waves_player.stop()


func _set_loop(stream: AudioStream) -> void:
	if stream is AudioStreamWAV:
		(stream as AudioStreamWAV).loop_mode = AudioStreamWAV.LOOP_FORWARD


func _ensure_audio_buses() -> void:
	for bus_name in [&"Master", &"Musica", &"SFX"]:
		var bus_index := AudioServer.get_bus_index(bus_name)
		if bus_index >= 0:
			AudioServer.set_bus_mute(bus_index, false)
			AudioServer.set_bus_volume_db(bus_index, 0.0)


func _set_player_bus(player: AudioStreamPlayer, bus_name: StringName) -> void:
	player.bus = bus_name if AudioServer.get_bus_index(bus_name) >= 0 else &"Master"
