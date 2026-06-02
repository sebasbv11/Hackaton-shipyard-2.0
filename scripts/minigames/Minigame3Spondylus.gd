extends "res://scripts/minigames/BaseCatchMinigame.gd"

const VEHICLE_PATH := "res://assets/placeholders/vehicles/surf_vehicle_placeholder.png"
const VEHICLE_CELL_W := 180.0
const VEHICLE_CELL_H := 201.5
const TARGET_DISTANCE := 2400.0
const TARGET_SHELLS := 7

var vehicle_texture: Texture2D = null
var surfer := Vector2(360, 900)
var water_speed := 300.0
var distance := 0.0
var shells := 0
var lives_left := 3
var jump_time := 0.0
var boost_time := 0.0
var wave_phase := 0.0
var surf_spawn_cd := 0.0
var lane_markers: Array[float] = [135.0, 260.0, 385.0, 510.0, 635.0]
var objects: Array[Dictionary] = []
var last_axis_x := 0.0

func _ready() -> void:
	title = "Minijuego 3: Surf Spondylus"
	place = "Playa de Manta"
	objective = "Surfea, salta obstaculos, toma rampas y recoge conchas Spondylus."
	reward = "Concha Spondylus"
	vehicle_texture = _load_vehicle_texture(VEHICLE_PATH)
	set_process(true)


func _process(delta: float) -> void:
	var axis_x := external_axis.x + _input_axis().x
	axis_x = clamp(axis_x, -1.0, 1.0)
	last_axis_x = axis_x

	wave_phase += delta * 5.0
	var speed_bonus := 130.0 if boost_time > 0.0 else 0.0
	var current_speed: float = water_speed + speed_bonus + min(distance * 0.035, 120.0)
	distance += delta * current_speed

	surfer.x = clamp(surfer.x + axis_x * 470.0 * delta, 70.0, SCREEN.x - 70.0)
	if jump_time > 0.0:
		jump_time -= delta
	if boost_time > 0.0:
		boost_time -= delta
	if Input.is_action_just_pressed("ui_accept"):
		action()

	surf_spawn_cd -= delta
	if surf_spawn_cd <= 0.0:
		surf_spawn_cd = randf_range(0.38, 0.72)
		_spawn_object()

	for i in range(objects.size() - 1, -1, -1):
		var obj := objects[i]
		var pos: Vector2 = obj["pos"]
		pos.y += obj["speed"] * delta + current_speed * delta * 0.45
		obj["pos"] = pos
		objects[i] = obj

		if pos.distance_to(surfer) < obj["radius"]:
			_handle_collision(obj)
			objects.remove_at(i)
		elif pos.y > SCREEN.y + 90.0:
			objects.remove_at(i)

	if distance >= TARGET_DISTANCE and shells >= TARGET_SHELLS:
		completed.emit(reward)

	queue_redraw()


func action() -> void:
	if jump_time <= 0.0:
		jump_time = 0.62


func _spawn_object() -> void:
	var roll := randf()
	var kind := "log"
	if roll > 0.72:
		kind = "shell"
	elif roll > 0.56:
		kind = "ramp"
	elif roll > 0.38:
		kind = "buoy"

	objects.append({
		"pos": Vector2(lane_markers.pick_random(), 205.0),
		"kind": kind,
		"speed": randf_range(130.0, 230.0),
		"radius": 46.0 if kind != "shell" else 42.0
	})


func _handle_collision(obj: Dictionary) -> void:
	match obj["kind"]:
		"shell":
			shells += 1
			boost_time = max(boost_time, 0.25)
		"ramp":
			jump_time = 0.75
			boost_time = 0.85
		"buoy":
			if jump_time <= 0.0:
				lives_left -= 1
		"log":
			if jump_time <= 0.0:
				lives_left -= 1

	if lives_left <= 0:
		failed.emit()


func _draw() -> void:
	_draw_surf_background()
	_draw_text(Vector2(28, 42), title, 31, Color("#f4e4bc"))
	_draw_text(Vector2(28, 86), "Izq/Der para surfear. Accion salta. Rampas dan turbo.", 18, Color.WHITE)
	_draw_text(
		Vector2(28, 126),
		"Ruta: %d/%d   Spondylus: %d/%d   Vidas: %d" % [int(distance), int(TARGET_DISTANCE), shells, TARGET_SHELLS, lives_left],
		16,
		Color("#48cae4")
	)

	for obj in objects:
		_draw_object(obj)

	var lift := _jump_lift()
	_draw_vehicle(surfer + Vector2(0, lift))


func _draw_surf_background() -> void:
	draw_rect(Rect2(Vector2.ZERO, SCREEN), Color("#06283d"))
	draw_rect(Rect2(0, 170, SCREEN.x, 950), Color("#0e86a7"))
	draw_rect(Rect2(0, 1120, SCREEN.x, 160), Color("#e9c46a"))

	for y in range(220, 1120, 44):
		var amp := sin(float(y) * 0.04 + wave_phase) * 28.0
		draw_line(Vector2(0, y), Vector2(SCREEN.x, y + amp), Color(1, 1, 1, 0.16), 5)
	for x in lane_markers:
		draw_line(Vector2(x, 185), Vector2(x + sin(wave_phase + x * 0.02) * 28.0, 1120), Color(1, 1, 1, 0.07), 3)

	draw_rect(Rect2(0, 1120, SCREEN.x, 32), Color("#f4e4bc"))
	draw_circle(Vector2(610, 1185), 42, Color("#e76f51"))
	draw_circle(Vector2(610, 1185), 20, Color("#f4e4bc"))


func _draw_object(obj: Dictionary) -> void:
	var pos: Vector2 = obj["pos"]
	match obj["kind"]:
		"shell":
			_draw_shell(pos)
		"ramp":
			_draw_ramp(pos)
		"buoy":
			_draw_buoy(pos)
		"log":
			_draw_log(pos)


func _draw_vehicle(pos: Vector2) -> void:
	if vehicle_texture == null:
		_draw_fallback_surfer(pos)
		return

	var col := 0
	if last_axis_x < -0.25:
		col = 2
	elif last_axis_x > 0.25:
		col = 5
	elif boost_time > 0.0:
		col = 1

	var row := 1 if jump_time > 0.0 else 0
	var source := Rect2(col * VEHICLE_CELL_W, row * VEHICLE_CELL_H, VEHICLE_CELL_W, VEHICLE_CELL_H)
	draw_texture_rect_region(vehicle_texture, Rect2(pos.x - 58, pos.y - 82, 116, 130), source)


func _draw_fallback_surfer(pos: Vector2) -> void:
	_draw_ellipse(Rect2(pos.x - 58, pos.y - 16, 116, 32), Color("#f4e4bc"))
	draw_rect(Rect2(pos.x - 16, pos.y - 70, 32, 48), Color("#e76f51"))


func _draw_shell(pos: Vector2) -> void:
	draw_circle(pos, 30, Color("#e76f51"))
	draw_circle(pos, 15, Color("#f4e4bc"))


func _draw_log(pos: Vector2) -> void:
	draw_rect(Rect2(pos.x - 48, pos.y - 18, 96, 36), Color("#7a4b24"))
	draw_rect(Rect2(pos.x - 36, pos.y - 7, 72, 8), Color("#5c3d1e"))


func _draw_buoy(pos: Vector2) -> void:
	draw_circle(pos, 28, Color("#f4e4bc"))
	draw_rect(Rect2(pos.x - 26, pos.y - 6, 52, 12), Color("#e63946"))


func _draw_ramp(pos: Vector2) -> void:
	_draw_polygon([
		pos + Vector2(-44, 24),
		pos + Vector2(44, 24),
		pos + Vector2(20, -28),
		pos + Vector2(-20, -28)
	], Color("#f4a261"))
	draw_line(pos + Vector2(-30, 14), pos + Vector2(24, -14), Color("#f4e4bc"), 5)


func _jump_lift() -> float:
	if jump_time <= 0.0:
		return 0.0
	var t := jump_time / 0.75
	return -sin(t * PI) * 90.0


func _load_vehicle_texture(path: String) -> Texture2D:
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
