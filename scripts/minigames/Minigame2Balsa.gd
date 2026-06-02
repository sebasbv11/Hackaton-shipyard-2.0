extends "res://scripts/minigames/BaseCatchMinigame.gd"

func _ready() -> void:
	title = "Minijuego 2: Balsa Mantena"
	place = "Memoria naval ancestral"
	objective = "Recupera piezas de la Silla U Mantena y evita las rocas."
	reward = "Silla U Mantena"
	good_label = "memoria mantena"
	bad_label = "roca"
	player_color = Color("#2a9d8f")
	good_color = Color("#2a9d8f")
	super._ready()


func _draw_good_item(pos: Vector2) -> void:
	draw_arc(pos, 25, 0, PI, 24, good_color, 6)
	draw_line(pos + Vector2(-25, 0), pos + Vector2(25, 0), good_color, 6)
