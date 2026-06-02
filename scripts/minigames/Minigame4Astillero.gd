extends "res://scripts/minigames/BaseCatchMinigame.gd"

const PARTS := ["quilla", "vela", "motor", "red"]
static var PART_COLORS := [Color("#48cae4"), Color("#f4e4bc"), Color("#adb5bd"), Color("#2a9d8f")]

var sequence := []
var cursor := 0
var progress := 0
var errors := 0
var axis_lock := false

func _ready() -> void:
	title = "Minijuego 4: Taller del Astillero"
	place = "Astilleros de Manta"
	objective = "Repara el Barco Jocay siguiendo la secuencia de piezas."
	reward = "Sello del Astillero"
	_build_sequence()
	set_process(true)


func _process(delta: float) -> void:
	if external_axis.x < -0.4 and not axis_lock:
		cursor = max(0, cursor - 1)
		axis_lock = true
	elif external_axis.x > 0.4 and not axis_lock:
		cursor = min(PARTS.size() - 1, cursor + 1)
		axis_lock = true
	elif abs(external_axis.x) < 0.2:
		axis_lock = false
	if Input.is_action_just_pressed("ui_left"):
		cursor = max(0, cursor - 1)
	if Input.is_action_just_pressed("ui_right"):
		cursor = min(PARTS.size() - 1, cursor + 1)
	if Input.is_action_just_pressed("ui_accept"):
		action()
	queue_redraw()


func action() -> void:
	if cursor == sequence[progress]:
		progress += 1
		if progress >= sequence.size():
			completed.emit(reward)
	else:
		errors += 1
		if errors >= 3:
			failed.emit()


func _build_sequence() -> void:
	sequence.clear()
	for i in range(7):
		sequence.append(randi_range(0, PARTS.size() - 1))


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, SCREEN), Color("#101820"))
	draw_rect(Rect2(0, 210, SCREEN.x, 1068), Color("#5c6b73"))
	for x in range(0, int(SCREEN.x), 44):
		draw_rect(Rect2(x, 210, 20, 1068), Color(0, 0, 0, 0.08))
	_draw_text(Vector2(28, 42), title, 31, Color("#f4e4bc"))
	_draw_text(Vector2(28, 86), "Izq/Der elige pieza. Accion instala.", 18, Color.WHITE)
	_draw_text(Vector2(28, 126), "Progreso: %d/%d   Errores: %d/3" % [progress, sequence.size(), errors], 16, Color("#48cae4"))

	_draw_ship_blueprint()
	_draw_sequence()
	_draw_parts()


func _draw_ship_blueprint() -> void:
	draw_rect(Rect2(90, 250, 540, 430), Color("#0a2540"))
	draw_line(Vector2(130, 560), Vector2(590, 560), Color("#48cae4"), 6)
	draw_arc(Vector2(360, 455), 220, 0, PI, 36, Color("#48cae4"), 7)
	draw_line(Vector2(360, 545), Vector2(360, 315), Color("#f4e4bc"), 7)
	_draw_polygon([Vector2(370, 320), Vector2(370, 500), Vector2(505, 500)], Color("#f4e4bc"))
	_draw_text(Vector2(228, 630), "Plano del Barco Jocay", 20, Color("#f4e4bc"))


func _draw_sequence() -> void:
	_draw_text(Vector2(75, 720), "Orden de reparacion", 21, Color("#f4e4bc"))
	for i in range(sequence.size()):
		var pos := Vector2(92 + i * 74, 775)
		var index: int = sequence[i]
		draw_rect(Rect2(pos.x - 22, pos.y - 22, 44, 44), PART_COLORS[index])
		if i < progress:
			draw_line(pos + Vector2(-20, 20), pos + Vector2(20, -20), Color("#2a9d8f"), 5)


func _draw_parts() -> void:
	for i in range(PARTS.size()):
		var pos := Vector2(120 + i * 155, 980)
		var selected := i == cursor
		draw_rect(Rect2(pos.x - 54, pos.y - 54, 108, 108), Color("#f4a261") if selected else Color("#343a40"))
		draw_rect(Rect2(pos.x - 44, pos.y - 44, 88, 88), PART_COLORS[i])
		_draw_text(pos + Vector2(-38, 78), PARTS[i], 16, Color("#f4e4bc"))
