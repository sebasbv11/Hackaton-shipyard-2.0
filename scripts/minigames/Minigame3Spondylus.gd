extends "res://scripts/minigames/BaseCatchMinigame.gd"

var surfer := Vector2(360, 880)
var speed_y := 210.0
var distance := 0.0
var jump_time := 0.0
var wave_phase := 0.0
var hazards: Array[Dictionary] = []
var surf_spawn_cd := 0.0
var shells := 0
var lives_left := 3

func _ready() -> void:
	title = "Minijuego 3: Surf Spondylus"
	place = "Playa de Manta"
	objective = "Surfea las olas, salta troncos y toma conchas Spondylus."
	reward = "Concha Spondylus"
	set_process(true)


func _process(delta: float) -> void:
	wave_phase += delta * 4.0
	distance += delta * speed_y
	surfer.x = clamp(surfer.x + external_axis.x * 380.0 * delta + _input_axis().x * 380.0 * delta, 80.0, SCREEN.x - 80.0)
	if jump_time > 0.0:
		jump_time -= delta
	if Input.is_action_just_pressed("ui_accept"):
		action()

	surf_spawn_cd -= delta
	if surf_spawn_cd <= 0.0:
		surf_spawn_cd = randf_range(0.65, 1.05)
		hazards.append({
			"pos": Vector2(randf_range(80.0, SCREEN.x - 80.0), 210.0),
			"kind": "shell" if randf() > 0.45 else "log",
			"speed": randf_range(250.0, 390.0)
		})

	for i in range(hazards.size() - 1, -1, -1):
		var h := hazards[i]
		var pos: Vector2 = h["pos"]
		pos.y += h["speed"] * delta
		h["pos"] = pos
		hazards[i] = h
		if pos.distance_to(surfer) < 58.0:
			if h["kind"] == "shell":
				shells += 1
				hazards.remove_at(i)
			elif jump_time <= 0.0:
				lives_left -= 1
				hazards.remove_at(i)
				if lives_left <= 0:
					failed.emit()
		elif pos.y > SCREEN.y + 60:
			hazards.remove_at(i)

	if distance >= 1700.0 and shells >= 4:
		completed.emit(reward)

	queue_redraw()


func action() -> void:
	if jump_time <= 0.0:
		jump_time = 0.55


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, SCREEN), Color("#06283d"))
	draw_rect(Rect2(0, 180, SCREEN.x, 980), Color("#0e86a7"))
	for y in range(230, 1120, 44):
		var amp := 20.0 + sin(float(y) * 0.05 + wave_phase) * 10.0
		draw_line(Vector2(0, y), Vector2(SCREEN.x, y + amp), Color(1, 1, 1, 0.16), 5)
	draw_rect(Rect2(0, 1160, SCREEN.x, 120), Color("#e9c46a"))

	_draw_text(Vector2(28, 42), title, 31, Color("#f4e4bc"))
	_draw_text(Vector2(28, 86), "Izq/Der para surfear. Accion salta troncos.", 18, Color.WHITE)
	_draw_text(Vector2(28, 126), "Ruta: %d/1700   Conchas: %d/4   Vidas: %d" % [int(distance), shells, lives_left], 16, Color("#48cae4"))

	for h in hazards:
		if h["kind"] == "shell":
			_draw_shell(h["pos"])
		else:
			_draw_log(h["pos"])

	var lift := -48.0 if jump_time > 0.0 else 0.0
	_draw_surfboard(surfer + Vector2(0, lift))


func _draw_surfboard(pos: Vector2) -> void:
	_draw_ellipse(Rect2(pos.x - 58, pos.y - 16, 116, 32), Color("#f4e4bc"))
	draw_rect(Rect2(pos.x - 16, pos.y - 70, 32, 48), Color("#e76f51"))
	draw_rect(Rect2(pos.x - 14, pos.y - 100, 28, 28), Color("#f4d0a4"))


func _draw_shell(pos: Vector2) -> void:
	draw_circle(pos, 30, Color("#e76f51"))
	draw_circle(pos, 15, Color("#f4e4bc"))


func _draw_log(pos: Vector2) -> void:
	draw_rect(Rect2(pos.x - 45, pos.y - 18, 90, 36), Color("#7a4b24"))
	draw_rect(Rect2(pos.x - 35, pos.y - 8, 70, 8), Color("#5c3d1e"))
