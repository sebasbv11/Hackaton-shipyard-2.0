extends "res://scripts/minigames/BaseCatchMinigame.gd"

static var BUBBLE_COLORS := [Color("#48cae4"), Color("#2a9d8f"), Color("#e76f51"), Color("#f4a261"), Color("#4361ee")]

var bubbles: Array[Dictionary] = []
var projectile := {}
var aim_angle := -PI / 2.0
var popped := 0
var shots := 18
var next_color := Color("#48cae4")

func _ready() -> void:
	title = "Minijuego 2: Silla U Bubble"
	place = "Memoria naval ancestral"
	objective = "Dispara burbujas y libera simbolos de la Silla U Mantena."
	reward = "Silla U Mantena"
	_build_bubble_wall()
	_pick_next_color()
	set_process(true)


func _process(delta: float) -> void:
	aim_angle = clamp(aim_angle + external_axis.x * delta * 1.6, -2.55, -0.58)
	if Input.is_action_just_pressed("ui_accept"):
		action()

	if projectile:
		var pos: Vector2 = projectile["pos"]
		pos += projectile["vel"] * delta
		projectile["pos"] = pos
		if pos.x < 28 or pos.x > SCREEN.x - 28:
			var vel: Vector2 = projectile["vel"]
			vel.x *= -1
			projectile["vel"] = vel
		if pos.y < 220:
			_miss_shot()
		else:
			for i in range(bubbles.size() - 1, -1, -1):
				if pos.distance_to(bubbles[i]["pos"]) < 38.0:
					_hit_bubble(i)
					break

	queue_redraw()


func action() -> void:
	if projectile or shots <= 0:
		return
	shots -= 1
	var dir := Vector2(cos(aim_angle), sin(aim_angle))
	projectile = {
		"pos": Vector2(360, 1095),
		"vel": dir * 620.0,
		"color": next_color
	}
	_pick_next_color()


func _build_bubble_wall() -> void:
	bubbles.clear()
	for row in range(6):
		for col in range(10):
			var offset := 28 if row % 2 == 1 else 0
			bubbles.append({
				"pos": Vector2(70 + col * 62 + offset, 260 + row * 48),
				"color": BUBBLE_COLORS[(row + col) % BUBBLE_COLORS.size()]
			})


func _hit_bubble(index: int) -> void:
	var hit_color: Color = bubbles[index]["color"]
	var projectile_color: Color = projectile["color"]
	if projectile_color != hit_color:
		projectile = {}
		if shots <= 0:
			failed.emit()
		return

	var to_remove := []
	for i in range(bubbles.size()):
		if bubbles[i]["color"] == hit_color and bubbles[i]["pos"].distance_to(bubbles[index]["pos"]) < 132.0:
			to_remove.append(i)
	to_remove.sort()
	to_remove.reverse()
	for i in to_remove:
		bubbles.remove_at(i)
	popped += to_remove.size()
	projectile = {}
	if popped >= 12:
		completed.emit(reward)
	elif shots <= 0:
		failed.emit()


func _miss_shot() -> void:
	projectile = {}
	if shots <= 0:
		failed.emit()


func _pick_next_color() -> void:
	next_color = BUBBLE_COLORS[randi_range(0, BUBBLE_COLORS.size() - 1)]


func _draw() -> void:
	_draw_ocean_background()
	_draw_text(Vector2(28, 42), title, 31, Color("#f4e4bc"))
	_draw_text(Vector2(28, 86), "Apunta con izquierda/derecha. Accion dispara.", 18, Color.WHITE)
	_draw_text(Vector2(28, 126), "Liberados: %d/12   Disparos: %d   Recompensa: %s" % [popped, shots, reward], 16, Color("#48cae4"))
	_draw_silla_u_big(Vector2(360, 790), Color(0.28, 0.79, 0.89, 0.18))

	for bubble in bubbles:
		draw_circle(bubble["pos"], 23, bubble["color"])
		draw_circle(bubble["pos"] + Vector2(-7, -7), 7, Color(1, 1, 1, 0.55))

	var shooter := Vector2(360, 1095)
	var aim_end := shooter + Vector2(cos(aim_angle), sin(aim_angle)) * 155.0
	draw_line(shooter, aim_end, Color("#f4e4bc"), 5)
	draw_circle(shooter, 30, Color("#e76f51"))
	draw_circle(Vector2(610, 1095), 24, next_color)
	_draw_text(Vector2(565, 1140), "Siguiente", 16, Color("#f4e4bc"))
	if projectile:
		draw_circle(projectile["pos"], 22, projectile["color"])


func _draw_silla_u_big(center: Vector2, color: Color) -> void:
	draw_arc(center, 150, 0.12, PI - 0.12, 36, color, 14)
	draw_line(center + Vector2(-148, -5), center + Vector2(-175, -150), color, 14)
	draw_line(center + Vector2(148, -5), center + Vector2(175, -150), color, 14)
	for i in range(13):
		_draw_diamond(center + Vector2(-108 + i * 18, 22 + sin(float(i) * 0.6) * 28), 8, Color("#48cae4"))


func _draw_diamond(center: Vector2, radius: float, color: Color) -> void:
	_draw_polygon([
		center + Vector2(0, -radius),
		center + Vector2(radius, 0),
		center + Vector2(0, radius),
		center + Vector2(-radius, 0)
	], color)
