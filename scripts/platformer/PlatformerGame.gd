extends Node2D

const SCREEN := Vector2(720, 1280)
const GRAVITY := 1900.0
const MOVE_SPEED := 360.0
const JUMP_SPEED := -760.0
const PLAYER_SIZE := Vector2(52, 76)
const SPRITE_PATH := "res://assets/player/player_retro_sprite_sheet.png"
const CELL_W := 102.0
const CELL_H := 152.75

var player_pos := Vector2(90, 860)
var player_vel := Vector2.ZERO
var facing := "right"
var frame_index := 0
var frame_time := 0.0
var touch_axis := Vector2.ZERO
var jump_queued := false
var current_level := 0
var coins_collected := {}
var total_coins := 0
var level_message := ""
var message_time := 0.0
var won := false
var player_texture: Texture2D = null

var title_label: Label
var stats_label: Label
var prompt_label: Label
var left_button: Button
var right_button: Button
var jump_button: Button
var restart_button: Button

var levels := [
	{
		"name": "Nivel 1: Playa Murcielago",
		"start": Vector2(90, 860),
		"exit": Rect2(610, 735, 58, 95),
		"platforms": [
			Rect2(0, 1010, 720, 90),
			Rect2(95, 850, 170, 32),
			Rect2(330, 760, 150, 32),
			Rect2(535, 650, 155, 32),
		],
		"coins": [
			Vector2(165, 800), Vector2(390, 710), Vector2(600, 600), Vector2(650, 600)
		],
		"hazards": [
			Rect2(280, 975, 70, 35), Rect2(485, 975, 70, 35)
		]
	},
	{
		"name": "Nivel 2: Astillero Jocay",
		"start": Vector2(70, 930),
		"exit": Rect2(610, 345, 58, 95),
		"platforms": [
			Rect2(0, 1040, 720, 90),
			Rect2(90, 900, 145, 32),
			Rect2(305, 810, 145, 32),
			Rect2(505, 710, 150, 32),
			Rect2(315, 580, 140, 32),
			Rect2(545, 465, 165, 32),
		],
		"coins": [
			Vector2(150, 850), Vector2(370, 760), Vector2(590, 660), Vector2(380, 530), Vector2(620, 415)
		],
		"hazards": [
			Rect2(250, 1005, 78, 35), Rect2(455, 1005, 78, 35), Rect2(475, 685, 58, 28)
		]
	}
]

func _ready() -> void:
	player_texture = _load_player_texture(SPRITE_PATH)
	_build_ui()
	_start_level(0)
	set_process(true)


func _process(delta: float) -> void:
	if message_time > 0.0:
		message_time -= delta
	if won:
		queue_redraw()
		return
	_update_player(delta)
	_update_ui()
	queue_redraw()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		jump_queued = true
	if event.is_action_pressed("ui_cancel"):
		_start_level(current_level)


func _update_player(delta: float) -> void:
	var axis := _input_axis() + touch_axis
	axis.x = clamp(axis.x, -1.0, 1.0)
	if axis.x != 0.0:
		facing = "right" if axis.x > 0.0 else "left"
	player_vel.x = axis.x * MOVE_SPEED
	player_vel.y += GRAVITY * delta

	var on_floor := _is_on_floor()
	if jump_queued and on_floor:
		player_vel.y = JUMP_SPEED
	jump_queued = false

	player_pos.x += player_vel.x * delta
	_resolve_collisions(Vector2(signf(player_vel.x), 0))
	player_pos.y += player_vel.y * delta
	_resolve_collisions(Vector2(0, signf(player_vel.y)))

	player_pos.x = clamp(player_pos.x, 30.0, SCREEN.x - 30.0)
	if player_pos.y > SCREEN.y + 120.0:
		_start_level(current_level)

	_collect_coins()
	_check_hazards()
	_check_exit()
	_update_animation(delta, axis)


func _input_axis() -> Vector2:
	var axis := Vector2.ZERO
	if Input.is_action_pressed("ui_left") or Input.is_key_pressed(KEY_A):
		axis.x -= 1.0
	if Input.is_action_pressed("ui_right") or Input.is_key_pressed(KEY_D):
		axis.x += 1.0
	return axis


func _resolve_collisions(direction: Vector2) -> void:
	var rect := _player_rect()
	for platform in levels[current_level]["platforms"]:
		if rect.intersects(platform):
			if direction.x > 0:
				player_pos.x = platform.position.x - PLAYER_SIZE.x * 0.5
			elif direction.x < 0:
				player_pos.x = platform.position.x + platform.size.x + PLAYER_SIZE.x * 0.5
			elif direction.y > 0:
				player_pos.y = platform.position.y - PLAYER_SIZE.y
				player_vel.y = 0.0
			elif direction.y < 0:
				player_pos.y = platform.position.y + platform.size.y
				player_vel.y = 0.0
			rect = _player_rect()


func _is_on_floor() -> bool:
	var test := _player_rect()
	test.position.y += 2
	for platform in levels[current_level]["platforms"]:
		if test.intersects(platform):
			return true
	return false


func _player_rect() -> Rect2:
	return Rect2(player_pos.x - PLAYER_SIZE.x * 0.5, player_pos.y - PLAYER_SIZE.y, PLAYER_SIZE.x, PLAYER_SIZE.y)


func _collect_coins() -> void:
	for i in range(levels[current_level]["coins"].size()):
		if coins_collected.has(i):
			continue
		var coin_pos: Vector2 = levels[current_level]["coins"][i]
		if coin_pos.distance_to(player_pos + Vector2(0, -42)) < 48.0:
			coins_collected[i] = true
			level_message = "Spondylus obtenida"
			message_time = 0.8


func _check_hazards() -> void:
	var rect := _player_rect()
	for hazard in levels[current_level]["hazards"]:
		if rect.intersects(hazard):
			level_message = "Cuidado con los obstaculos del muelle"
			message_time = 1.0
			_start_level(current_level)
			return


func _check_exit() -> void:
	if not _player_rect().intersects(levels[current_level]["exit"]):
		return
	if coins_collected.size() < levels[current_level]["coins"].size():
		level_message = "Recoge todas las conchas antes de avanzar"
		message_time = 1.2
		return
	if current_level + 1 >= levels.size():
		won = true
		level_message = "Ruta Spondylus completada"
		message_time = 999.0
	else:
		_start_level(current_level + 1)


func _start_level(index: int) -> void:
	current_level = index
	player_pos = levels[current_level]["start"]
	player_vel = Vector2.ZERO
	coins_collected.clear()
	total_coins = levels[current_level]["coins"].size()
	won = false
	level_message = levels[current_level]["name"]
	message_time = 1.5


func _update_animation(delta: float, axis: Vector2) -> void:
	if abs(axis.x) > 0.05:
		frame_time += delta
		if frame_time >= 0.12:
			frame_time = 0.0
			frame_index = (frame_index + 1) % 4
	else:
		frame_index = 0


func _build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	title_label = _make_label(layer, Vector2(24, 24), Vector2(670, 40), 27, Color("#f4e4bc"))
	stats_label = _make_label(layer, Vector2(24, 70), Vector2(670, 42), 17, Color("#48cae4"))
	prompt_label = _make_label(layer, Vector2(60, 1120), Vector2(600, 48), 18, Color("#f4e4bc"))
	prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_add_button(layer, "left", "<", Vector2(44, 1160), Vector2(-1, 0))
	_add_button(layer, "right", ">", Vector2(150, 1160), Vector2(1, 0))
	jump_button = Button.new()
	jump_button.text = "SALTAR"
	jump_button.position = Vector2(500, 1160)
	jump_button.size = Vector2(150, 64)
	jump_button.pressed.connect(func(): jump_queued = true)
	layer.add_child(jump_button)
	restart_button = Button.new()
	restart_button.text = "Reintentar"
	restart_button.position = Vector2(330, 1160)
	restart_button.size = Vector2(145, 64)
	restart_button.pressed.connect(func(): _start_level(current_level))
	layer.add_child(restart_button)


func _make_label(layer: CanvasLayer, pos: Vector2, size: Vector2, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.position = pos
	label.size = size
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	layer.add_child(label)
	return label


func _add_button(layer: CanvasLayer, key: String, text: String, pos: Vector2, axis: Vector2) -> void:
	var button := Button.new()
	button.text = text
	button.position = pos
	button.size = Vector2(86, 64)
	button.button_down.connect(func(): touch_axis += axis)
	button.button_up.connect(func(): touch_axis -= axis)
	layer.add_child(button)


func _update_ui() -> void:
	title_label.text = levels[current_level]["name"]
	stats_label.text = "Conchas: %d/%d   Nivel: %d/%d" % [coins_collected.size(), total_coins, current_level + 1, levels.size()]
	prompt_label.text = level_message if message_time > 0.0 else "Recoge todas las conchas y llega al portal"


func _draw() -> void:
	_draw_background()
	_draw_level()
	_draw_player()
	if won:
		draw_rect(Rect2(55, 500, 610, 180), Color(0, 0, 0, 0.74))
		_draw_text(Vector2(120, 585), "Victoria: Ruta Spondylus completada", 30, Color("#f4e4bc"))


func _draw_background() -> void:
	draw_rect(Rect2(Vector2.ZERO, SCREEN), Color("#071b35"))
	draw_rect(Rect2(0, 0, SCREEN.x, 220), Color("#12345c"))
	draw_circle(Vector2(600, 105), 46, Color("#f4a261"))
	draw_rect(Rect2(0, 220, SCREEN.x, 780), Color("#147a9e"))
	draw_rect(Rect2(0, 1000, SCREEN.x, 280), Color("#d8b56f"))
	for y in range(260, 980, 42):
		draw_line(Vector2(0, y), Vector2(SCREEN.x, y + sin(float(y) * 0.09) * 18.0), Color(1, 1, 1, 0.12), 4)
	_draw_port_silhouette()


func _draw_level() -> void:
	for platform in levels[current_level]["platforms"]:
		draw_rect(platform, Color("#7a4b24"))
		draw_rect(Rect2(platform.position, Vector2(platform.size.x, 9)), Color("#b8793c"))
		for x in range(int(platform.position.x), int(platform.position.x + platform.size.x), 28):
			draw_rect(Rect2(x, platform.position.y + 11, 14, platform.size.y - 11), Color(0, 0, 0, 0.12))

	for hazard in levels[current_level]["hazards"]:
		draw_rect(hazard, Color("#5c3d1e"))
		for x in range(int(hazard.position.x), int(hazard.position.x + hazard.size.x), 18):
			_draw_triangle(Vector2(x + 9, hazard.position.y), 16, Color("#e63946"))

	for i in range(levels[current_level]["coins"].size()):
		if coins_collected.has(i):
			continue
		_draw_spondylus(levels[current_level]["coins"][i])

	var exit_rect: Rect2 = levels[current_level]["exit"]
	draw_rect(exit_rect, Color("#264653"))
	draw_rect(Rect2(exit_rect.position + Vector2(8, 8), exit_rect.size - Vector2(16, 16)), Color("#48cae4"))
	_draw_text(exit_rect.position + Vector2(-14, -12), "SALIDA", 14, Color("#f4e4bc"))


func _draw_player() -> void:
	if player_texture == null:
		draw_rect(_player_rect(), Color("#e76f51"))
		return
	var row := 0.0
	if facing == "left":
		row = 2.0
	elif facing == "right":
		row = 3.0
	var source := Rect2(CELL_W * frame_index, CELL_H * row, CELL_W, CELL_H)
	draw_texture_rect_region(player_texture, Rect2(player_pos.x - 38, player_pos.y - 112, 76, 112), source)


func _draw_port_silhouette() -> void:
	for i in range(8):
		var x := 30 + i * 82
		var h := 34 + (i % 3) * 18
		draw_rect(Rect2(x, 185 - h, 45, h), Color("#0b2442"))
	draw_line(Vector2(460, 176), Vector2(610, 96), Color("#0b2442"), 6)
	draw_line(Vector2(610, 96), Vector2(670, 176), Color("#0b2442"), 6)


func _draw_spondylus(pos: Vector2) -> void:
	draw_circle(pos, 24, Color("#e76f51"))
	draw_circle(pos, 12, Color("#f4e4bc"))
	draw_line(pos + Vector2(-16, 8), pos + Vector2(16, -8), Color("#f4a261"), 3)


func _draw_triangle(pos: Vector2, size: float, color: Color) -> void:
	draw_polygon(PackedVector2Array([
		pos + Vector2(0, -size),
		pos + Vector2(size, size),
		pos + Vector2(-size, size)
	]), PackedColorArray([color]))


func _draw_text(pos: Vector2, text: String, size: int, color: Color) -> void:
	draw_string(ThemeDB.fallback_font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)


func _load_player_texture(path: String) -> Texture2D:
	var image := Image.load_from_file(path)
	if image == null:
		return null
	_make_black_transparent(image)
	return ImageTexture.create_from_image(image)


func _make_black_transparent(image: Image) -> void:
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			var color := image.get_pixel(x, y)
			if color.r < 0.04 and color.g < 0.04 and color.b < 0.04:
				color.a = 0.0
				image.set_pixel(x, y, color)
