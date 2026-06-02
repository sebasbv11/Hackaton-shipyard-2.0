extends Node2D

const GameData = preload("res://scripts/data/GameData.gd")
const SCREEN := Vector2(720, 1280)
const PLAYER_SPEED := 300.0
const INTERACT_DISTANCE := 92.0

var player_pos := Vector2(360, 930)
var touch_axis := Vector2.ZERO
var current_boat := -1
var completed := {}
var rewards: Array[String] = []
var final_started := false
var current_minigame: BaseCatchMinigame = null
var message := ""
var message_time := 0.0

var title_label: Label
var help_label: Label
var reward_label: Label
var prompt_label: Label
var interact_button: Button
var exit_button: Button
var move_buttons := {}

func _ready() -> void:
	randomize()
	_build_ui()
	_show_hub_text()
	set_process(true)


func _process(delta: float) -> void:
	if message_time > 0.0:
		message_time -= delta
		if message_time <= 0.0:
			message = ""

	if current_minigame:
		current_minigame.set_external_axis(touch_axis)
	elif final_started:
		player_pos.x = lerp(player_pos.x, 360.0, delta * 1.5)
		player_pos.y = lerp(player_pos.y, 545.0, delta * 1.5)
	else:
		_process_exploration(delta)

	queue_redraw()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		if current_minigame:
			current_minigame.action()
		else:
			_try_interact()
	if event.is_action_pressed("ui_cancel") and current_minigame:
		current_minigame.cancel()


func _process_exploration(delta: float) -> void:
	var axis := _keyboard_axis() + touch_axis
	if axis.length() > 1.0:
		axis = axis.normalized()

	player_pos += axis * PLAYER_SPEED * delta
	player_pos.x = clamp(player_pos.x, 70.0, SCREEN.x - 70.0)
	player_pos.y = clamp(player_pos.y, 360.0, SCREEN.y - 130.0)

	current_boat = _nearest_boat()
	prompt_label.text = ""

	if rewards.size() >= GameData.BOATS.size() and player_pos.distance_to(GameData.FINAL_POSITION) < 120.0:
		prompt_label.text = "Toca Interactuar para unir las 4 piezas en EL ASTILLERO"

	if current_boat >= 0:
		var boat: Dictionary = GameData.BOATS[current_boat]
		var done := completed.has(current_boat)
		prompt_label.text = "%s - %s\n%s" % [
			boat["name"],
			"completado" if done else "minijuego disponible",
			"Toca Interactuar" if not done else "Ya obtuviste: " + boat["reward"]
		]


func _keyboard_axis() -> Vector2:
	var axis := Vector2.ZERO
	if Input.is_action_pressed("ui_left") or Input.is_key_pressed(KEY_A):
		axis.x -= 1.0
	if Input.is_action_pressed("ui_right") or Input.is_key_pressed(KEY_D):
		axis.x += 1.0
	if Input.is_action_pressed("ui_up") or Input.is_key_pressed(KEY_W):
		axis.y -= 1.0
	if Input.is_action_pressed("ui_down") or Input.is_key_pressed(KEY_S):
		axis.y += 1.0
	return axis.normalized() if axis.length() > 1.0 else axis


func _nearest_boat() -> int:
	var found := -1
	var best := INTERACT_DISTANCE
	for i in range(GameData.BOATS.size()):
		var d := player_pos.distance_to(GameData.BOATS[i]["position"])
		if d < best:
			best = d
			found = i
	return found


func _try_interact() -> void:
	if final_started:
		return

	if rewards.size() >= GameData.BOATS.size() and player_pos.distance_to(GameData.FINAL_POSITION) < 120.0:
		_start_final_event()
		return

	if current_boat < 0 or completed.has(current_boat):
		_flash("Acercate a un barco del muelle para iniciar un minijuego.", 1.4)
		return

	_start_minigame(current_boat)


func _start_minigame(index: int) -> void:
	var boat: Dictionary = GameData.BOATS[index]
	var minigame_scene := load(boat["scene"]) as PackedScene
	if not minigame_scene:
		_flash("No se pudo cargar el minijuego: " + boat["name"], 1.8)
		return
	current_minigame = minigame_scene.instantiate() as BaseCatchMinigame
	add_child(current_minigame)
	current_minigame.completed.connect(_on_minigame_completed.bind(index))
	current_minigame.failed.connect(_on_minigame_failed)

	title_label.visible = false
	help_label.visible = false
	reward_label.visible = false
	prompt_label.visible = false
	interact_button.visible = false
	interact_button.text = "Accion"
	interact_button.position = Vector2(350, 1160)
	interact_button.size = Vector2(145, 64)
	interact_button.visible = true
	exit_button.visible = true
	exit_button.position = Vector2(530, 1160)
	exit_button.size = Vector2(125, 64)
	_set_all_move_buttons_visible(false)
	move_buttons["left"].visible = true
	move_buttons["right"].visible = true


func _on_minigame_completed(reward: String, index: int) -> void:
	completed[index] = true
	if not rewards.has(reward):
		rewards.append(reward)
	_end_minigame()
	_flash("Recompensa obtenida: " + reward, 2.0)


func _on_minigame_failed() -> void:
	_end_minigame()
	_flash("Intentalo de nuevo. El muelle sigue esperandote.", 1.6)


func _end_minigame() -> void:
	if current_minigame:
		current_minigame.queue_free()
	current_minigame = null
	touch_axis = Vector2.ZERO

	title_label.visible = true
	help_label.visible = true
	reward_label.visible = true
	prompt_label.visible = true
	interact_button.visible = true
	interact_button.text = "Interactuar"
	interact_button.position = Vector2(470, 1160)
	interact_button.size = Vector2(185, 64)
	exit_button.visible = false
	_set_all_move_buttons_visible(true)
	_show_hub_text()


func _start_final_event() -> void:
	final_started = true
	title_label.text = GameData.FINAL_TITLE
	help_label.text = GameData.FINAL_TEXT
	prompt_label.text = ""
	interact_button.visible = false
	_set_all_move_buttons_visible(false)
	_flash("Evento final desbloqueado: Zarpar el Barco Jocay", 3.0)


func _show_hub_text() -> void:
	title_label.text = "Muelle de Manta"
	help_label.text = "Explora el puerto, la playa y EL ASTILLERO. Sube a 4 barcos, gana piezas culturales y desbloquea la zarpada final."
	_update_rewards_text()


func _update_rewards_text() -> void:
	if rewards.is_empty():
		reward_label.text = "Piezas reunidas: 0/4"
	else:
		reward_label.text = "Piezas reunidas: %d/4 - %s" % [rewards.size(), ", ".join(rewards)]


func _flash(text: String, seconds: float) -> void:
	message = text
	message_time = seconds
	_update_rewards_text()


func _build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)

	title_label = _make_label(layer, Vector2(28, 28), Vector2(660, 40), 28, Color("#f4e4bc"))
	help_label = _make_label(layer, Vector2(28, 76), Vector2(660, 74), 17, Color.WHITE)
	reward_label = _make_label(layer, Vector2(28, 155), Vector2(660, 56), 16, Color("#48cae4"))

	prompt_label = _make_label(layer, Vector2(70, 1080), Vector2(580, 70), 18, Color("#f4e4bc"))
	prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	interact_button = Button.new()
	interact_button.text = "Interactuar"
	interact_button.position = Vector2(470, 1160)
	interact_button.size = Vector2(185, 64)
	interact_button.pressed.connect(_on_interact_button_pressed)
	layer.add_child(interact_button)

	exit_button = Button.new()
	exit_button.text = "Salir"
	exit_button.position = Vector2(470, 1160)
	exit_button.size = Vector2(185, 64)
	exit_button.visible = false
	exit_button.pressed.connect(func():
		if current_minigame:
			current_minigame.cancel()
	)
	layer.add_child(exit_button)

	_add_move_button(layer, "left", "<", Vector2(45, 1160), Vector2(-1, 0))
	_add_move_button(layer, "right", ">", Vector2(205, 1160), Vector2(1, 0))
	_add_move_button(layer, "up", "^", Vector2(125, 1085), Vector2(0, -1))
	_add_move_button(layer, "down", "v", Vector2(125, 1160), Vector2(0, 1))


func _make_label(layer: CanvasLayer, pos: Vector2, size: Vector2, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.position = pos
	label.size = size
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	layer.add_child(label)
	return label


func _add_move_button(layer: CanvasLayer, key: String, text: String, pos: Vector2, axis: Vector2) -> void:
	var btn := Button.new()
	btn.text = text
	btn.position = pos
	btn.size = Vector2(72, 64)
	btn.button_down.connect(func(): touch_axis += axis)
	btn.button_up.connect(func(): touch_axis -= axis)
	layer.add_child(btn)
	move_buttons[key] = btn


func _set_all_move_buttons_visible(visible: bool) -> void:
	for button in move_buttons.values():
		button.visible = visible


func _on_interact_button_pressed() -> void:
	if current_minigame:
		current_minigame.action()
	else:
		_try_interact()


func _draw() -> void:
	if current_minigame:
		return

	_draw_hub()

	if final_started:
		_draw_final_ship()

	if message != "":
		_draw_message()


func _draw_hub() -> void:
	_draw_manta_background()

	_draw_pier()
	_draw_beach_symbols()
	_draw_astillero()
	_draw_all_boats()

	if rewards.size() >= GameData.BOATS.size():
		_draw_final_marker()

	_draw_player()


func _draw_manta_background() -> void:
	draw_rect(Rect2(Vector2.ZERO, SCREEN), Color("#071b35"))
	draw_rect(Rect2(0, 0, SCREEN.x, 210), Color("#12345c"))
	draw_circle(Vector2(592, 112), 50, Color("#f4a261"))
	draw_rect(Rect2(0, 205, SCREEN.x, 570), Color("#116d90"))
	draw_rect(Rect2(0, 760, SCREEN.x, 520), Color("#d8b56f"))
	draw_rect(Rect2(0, 710, SCREEN.x, 86), Color("#efcf8b"))
	for y in range(240, 735, 42):
		draw_line(Vector2(0, y), Vector2(SCREEN.x, y + sin(float(y) * 0.1) * 22.0), Color(1, 1, 1, 0.12), 3)
	for x in range(0, int(SCREEN.x), 36):
		draw_rect(Rect2(x, 760 + (x % 72) * 0.2, 18, 520), Color(0, 0, 0, 0.035))
	_draw_pixel_cloud(Vector2(72, 88))
	_draw_pixel_cloud(Vector2(350, 128))
	_draw_city_silhouette()
	_draw_palm(Vector2(95, 760))
	_draw_palm(Vector2(640, 790))


func _draw_city_silhouette() -> void:
	for i in range(8):
		var x := 28 + i * 72
		var h := 28 + (i % 3) * 18
		draw_rect(Rect2(x, 176 - h, 42, h), Color("#0b2442"))
		draw_rect(Rect2(x + 8, 184 - h, 8, 8), Color("#48cae4"))
		draw_rect(Rect2(x + 25, 184 - h, 8, 8), Color("#48cae4"))


func _draw_pixel_cloud(pos: Vector2) -> void:
	var c := Color(1, 1, 1, 0.78)
	draw_rect(Rect2(pos.x, pos.y, 46, 18), c)
	draw_rect(Rect2(pos.x + 18, pos.y - 14, 54, 26), c)
	draw_rect(Rect2(pos.x + 58, pos.y, 46, 18), c)


func _draw_palm(pos: Vector2) -> void:
	draw_rect(Rect2(pos.x - 8, pos.y - 80, 16, 82), Color("#7a4b24"))
	for i in range(5):
		var angle := -PI * 0.85 + i * PI * 0.42
		var end := pos + Vector2(cos(angle), sin(angle)) * 72 + Vector2(0, -85)
		draw_line(pos + Vector2(0, -82), end, Color("#2a9d8f"), 8)


func _draw_pier() -> void:
	draw_rect(Rect2(295, 360, 130, 600), Color("#8b5a2b"))
	for y in range(380, 940, 58):
		draw_rect(Rect2(295, y, 130, 8), Color("#5c3d1e"))
	for x in [285, 425]:
		for y in range(390, 950, 95):
			draw_circle(Vector2(x, y), 14, Color("#5c3d1e"))

	_draw_text(Vector2(250, 336), "MUELLE DE MANTA", 24, Color("#f4e4bc"))
	_draw_text(Vector2(38, 1010), "Playa, pesca artesanal y memoria mantena", 18, Color("#0a2540"))


func _draw_beach_symbols() -> void:
	draw_circle(Vector2(95, 900), 34, Color("#e76f51"))
	draw_circle(Vector2(95, 900), 18, Color("#f4e4bc"))
	_draw_text(Vector2(42, 952), "Concha Spondylus", 17, Color("#0a2540"))

	_draw_silla_u(Vector2(235, 1030), 0.9, Color("#2aa7c9"))
	_draw_text(Vector2(168, 1078), "Silla U Mantena", 17, Color("#0a2540"))


func _draw_astillero() -> void:
	draw_rect(Rect2(448, 880, 220, 210), Color("#495057"))
	draw_rect(Rect2(465, 895, 185, 180), Color("#6c757d"))
	draw_rect(Rect2(490, 845, 135, 62), Color("#495057"))
	_draw_polygon([Vector2(465, 895), Vector2(555, 825), Vector2(650, 895)], Color("#343a40"))
	draw_rect(Rect2(495, 955, 52, 80), Color("#212529"))
	draw_rect(Rect2(568, 955, 52, 80), Color("#212529"))
	_draw_text(Vector2(482, 914), "EL ASTILLERO", 22, Color("#f4e4bc"))
	_draw_text(Vector2(475, 1090), "reparacion naval", 15, Color("#0a2540"))
	draw_line(Vector2(455, 875), Vector2(650, 1040), Color("#212529"), 5)
	draw_line(Vector2(650, 875), Vector2(455, 1040), Color("#212529"), 5)


func _draw_all_boats() -> void:
	for i in range(GameData.BOATS.size()):
		var boat: Dictionary = GameData.BOATS[i]
		var pos: Vector2 = boat["position"]
		var done := completed.has(i)
		var col: Color = boat["color"]
		if done:
			col = col.lightened(0.35)

		_draw_ellipse(Rect2(pos.x - 70, pos.y - 24, 140, 48), Color("#5c3d1e"))
		_draw_ellipse(Rect2(pos.x - 62, pos.y - 32, 124, 48), col)
		draw_rect(Rect2(pos.x - 4, pos.y - 84, 8, 72), Color("#f4e4bc"))
		_draw_polygon([pos + Vector2(6, -78), pos + Vector2(6, -20), pos + Vector2(45, -20)], Color("#ffffff"))

		if done:
			draw_circle(pos + Vector2(52, -42), 18, Color("#2a9d8f"))
			_draw_text(pos + Vector2(45, -30), "ok", 13, Color.WHITE)

		_draw_text(pos + Vector2(-72, 45), boat["name"], 16, Color("#f8f9fa"))


func _draw_player() -> void:
	draw_rect(Rect2(player_pos.x - 18, player_pos.y + 0, 36, 40), Color("#e76f51"))
	draw_rect(Rect2(player_pos.x - 12, player_pos.y + 40, 10, 24), Color("#264653"))
	draw_rect(Rect2(player_pos.x + 2, player_pos.y + 40, 10, 24), Color("#264653"))
	draw_rect(Rect2(player_pos.x - 18, player_pos.y - 36, 36, 36), Color("#f4e4bc"))
	draw_rect(Rect2(player_pos.x - 20, player_pos.y - 42, 40, 12), Color("#264653"))
	draw_rect(Rect2(player_pos.x - 7, player_pos.y - 20, 5, 5), Color("#0a2540"))
	draw_rect(Rect2(player_pos.x + 7, player_pos.y - 20, 5, 5), Color("#0a2540"))


func _draw_final_marker() -> void:
	draw_circle(GameData.FINAL_POSITION, 70, Color(0.28, 0.79, 0.89, 0.22))
	draw_arc(GameData.FINAL_POSITION, 70, 0, TAU, 48, Color("#48cae4"), 4)
	_draw_text(GameData.FINAL_POSITION + Vector2(-63, 0), "Unir piezas", 18, Color("#f4e4bc"))


func _draw_final_ship() -> void:
	var ship_pos := Vector2(player_pos.x, player_pos.y - 70)
	_draw_ellipse(Rect2(ship_pos.x - 125, ship_pos.y - 35, 250, 70), Color("#5c3d1e"))
	_draw_ellipse(Rect2(ship_pos.x - 105, ship_pos.y - 55, 210, 70), Color("#48cae4"))
	draw_rect(Rect2(ship_pos.x - 5, ship_pos.y - 160, 10, 130), Color("#f4e4bc"))
	_draw_polygon([ship_pos + Vector2(8, -152), ship_pos + Vector2(8, -45), ship_pos + Vector2(90, -45)], Color("#ffffff"))
	_draw_text(ship_pos + Vector2(-70, 20), "BARCO JOCAY", 22, Color("#f4e4bc"))


func _draw_message() -> void:
	draw_rect(Rect2(45, 610, 630, 92), Color(0, 0, 0, 0.72))
	_draw_text(Vector2(70, 665), message, 22, Color("#f4e4bc"))


func _draw_text(pos: Vector2, text: String, size: int, color: Color) -> void:
	draw_string(ThemeDB.fallback_font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)


func _draw_ellipse(rect: Rect2, color: Color) -> void:
	var points := PackedVector2Array()
	var center := rect.position + rect.size * 0.5
	var radius := rect.size * 0.5
	for i in range(32):
		var angle := TAU * float(i) / 32.0
		points.append(center + Vector2(cos(angle) * radius.x, sin(angle) * radius.y))
	draw_polygon(points, PackedColorArray([color]))


func _draw_polygon(points: Array, color: Color) -> void:
	draw_polygon(PackedVector2Array(points), PackedColorArray([color]))


func _draw_silla_u(center: Vector2, scale: float, color: Color) -> void:
	var left := center + Vector2(-62, -70) * scale
	var right := center + Vector2(62, -70) * scale
	var bottom := center + Vector2(0, 32) * scale
	draw_line(left, center + Vector2(-52, -10) * scale, color, 5 * scale)
	draw_arc(bottom + Vector2(0, -42) * scale, 62 * scale, 0.12, PI - 0.12, 30, color, 5 * scale)
	draw_line(right, center + Vector2(52, -10) * scale, color, 5 * scale)
	draw_rect(Rect2(left.x - 18 * scale, left.y - 16 * scale, 32 * scale, 22 * scale), color)
	draw_rect(Rect2(right.x - 14 * scale, right.y - 16 * scale, 32 * scale, 22 * scale), color)
	for i in range(9):
		var x := center.x - 48 * scale + i * 12 * scale
		var y := center.y + sin(float(i) * 0.65) * 16 * scale
		_draw_diamond(Vector2(x, y), 7 * scale, color)
	draw_circle(center + Vector2(0, 68) * scale, 28 * scale, color)
	draw_circle(center + Vector2(0, 68) * scale, 20 * scale, Color("#d8f7ff"))
	draw_rect(Rect2(center.x - 55 * scale, center.y + 95 * scale, 110 * scale, 18 * scale), color)


func _draw_diamond(center: Vector2, radius: float, color: Color) -> void:
	_draw_polygon([
		center + Vector2(0, -radius),
		center + Vector2(radius, 0),
		center + Vector2(0, radius),
		center + Vector2(-radius, 0)
	], color)
