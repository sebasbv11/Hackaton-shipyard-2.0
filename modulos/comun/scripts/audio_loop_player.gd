extends AudioStreamPlayer

@export var reproducir_al_iniciar := true


func _ready() -> void:
	_configurar_loop()
	if not finished.is_connected(_reproducir_loop):
		finished.connect(_reproducir_loop)
	if reproducir_al_iniciar and not playing:
		play()


func _configurar_loop() -> void:
	if stream is AudioStreamWAV:
		var wav := stream as AudioStreamWAV
		wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
		if wav.loop_end <= 0:
			wav.loop_end = int(wav.mix_rate * wav.get_length())


func _reproducir_loop() -> void:
	if is_inside_tree():
		play()
