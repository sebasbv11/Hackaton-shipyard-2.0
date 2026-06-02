extends "res://scripts/minigames/BaseCatchMinigame.gd"

func _ready() -> void:
	title = "Minijuego 4: El Astillero"
	place = "Astilleros de Manta"
	objective = "Recoge piezas navales y evita herramientas danadas."
	reward = "Sello del Astillero"
	good_label = "pieza naval"
	bad_label = "herramienta danada"
	player_color = Color("#48cae4")
	good_color = Color("#adb5bd")
	super._ready()


func _draw_good_item(pos: Vector2) -> void:
	draw_rect(Rect2(pos.x - 22, pos.y - 18, 44, 36), good_color)
	draw_line(pos + Vector2(-20, 17), pos + Vector2(20, -17), Color("#48cae4"), 5)
