extends Control

## Muestra Flappy Pescador en 720x1280 (vertical) centrado dentro del proyecto landscape.

const GAME_SIZE := Vector2(720.0, 1280.0)

@onready var _container: SubViewportContainer = $ViewportContainer


func _ready() -> void:
	resized.connect(_refit_viewport)
	call_deferred("_refit_viewport")


func _refit_viewport() -> void:
	var area := get_viewport_rect().size
	if area.x < 1.0 or area.y < 1.0:
		return
	var scale := minf(area.x / GAME_SIZE.x, area.y / GAME_SIZE.y)
	var fitted := GAME_SIZE * scale
	_container.size = fitted
	_container.position = (area - fitted) * 0.5
