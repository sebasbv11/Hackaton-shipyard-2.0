extends "res://scripts/minigames/BaseCatchMinigame.gd"

func _ready() -> void:
	title = "Minijuego 1: Pesca responsable"
	place = "Puerto pesquero de Manta"
	objective = "Recoge peces de pesca responsable y evita la basura marina."
	reward = "Estatua del Pescador"
	good_label = "pesca responsable"
	bad_label = "basura marina"
	player_color = Color("#f4a261")
	good_color = Color("#48cae4")
	super._ready()


func _draw_good_item(pos: Vector2) -> void:
	_draw_ellipse(Rect2(pos.x - 22, pos.y - 12, 44, 24), good_color)
	draw_polygon([pos + Vector2(-22, 0), pos + Vector2(-38, -12), pos + Vector2(-38, 12)], [Color("#023e8a")])
