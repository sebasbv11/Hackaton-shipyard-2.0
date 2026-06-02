extends "res://scripts/minigames/BaseCatchMinigame.gd"

func _ready() -> void:
	title = "Minijuego 3: Ruta Spondylus"
	place = "Playa de Manta"
	objective = "Atrapa conchas Spondylus y evita las olas fuertes."
	reward = "Concha Spondylus"
	good_label = "Spondylus"
	bad_label = "ola fuerte"
	player_color = Color("#e76f51")
	good_color = Color("#e76f51")
	super._ready()
