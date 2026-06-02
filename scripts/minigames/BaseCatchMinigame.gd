extends Node2D
class_name BaseCatchMinigame

signal completed(reward: String)
signal failed

const SCREEN := Vector2(720, 1280)
const TARGET_SCORE := 5

var title := "Minijuego"
var place := "Manta"
var objective := "Atrapa los objetos buenos."
var reward := "Pieza de Manta"
var good_label := "pieza"
var bad_label := "obstaculo"
var player_color := Color("#48cae4")
var accent_color := Color("#f4a261")
var good_color := Color("#2a9d8f")
var bad_color := Color("#343a40")

var player_x := 360.0
var score := 0
var lives := 3
var spawn_cd := 0.0
var items: Array[Dictionary] = []
var external_axis := Vector2.ZERO
var banner := ""
var banner_time := 0.0

func _ready() -> void:
	set_process(true)


func set_external_axis(axis: Vector2) -> void:
	external_axis = axis


func cancel() -> void:
	failed.emit()


func _process(delta: float) -> void:
	if banner_time > 0.0:
		banner_time -= delta
		if banner_time <= 0.0:
			banner = ""

	var axis := _input_axis().x + external_axis.x
	player_x = clamp(player_x + axis * 430.0 * delta, 75.0, SCREEN.x - 75.0)

	spawn_cd -= delta
	if spawn_cd <= 0.0:
		spawn_cd = randf_range(0.45, 0.85)
		_spawn_item()

	for i in range(items.size() - 1, -1, -1):
		var item := items[i]
		var item_pos: Vector2 = item["pos"]
		item_pos.y += item["speed"] * delta
		item["pos"] = item_pos
		items[i] = item

		if item_pos.y > 1035.0 and abs(item_pos.x - player_x) < 70.0:
			_collect_item(item)
			items.remove_at(i)
		elif item_pos.y > SCREEN.y + 60.0:
			items.remove_at(i)

	queue_redraw()


func _input_axis() -> Vector2:
	var axis := Vector2.ZERO
	if Input.is_action_pressed("ui_left") or Input.is_key_pressed(KEY_A):
		axis.x -= 1.0
	if Input.is_action_pressed("ui_right") or Input.is_key_pressed(KEY_D):
		axis.x += 1.0
	return axis


func _spawn_item() -> void:
	items.append({
		"pos": Vector2(randf_range(85.0, SCREEN.x - 85.0), 205.0),
		"speed": randf_range(280.0, 430.0),
		"good": randf() > 0.28
	})


func _collect_item(item: Dictionary) -> void:
	if item["good"]:
		score += 1
		_show_banner("+1 " + good_label)
		if score >= TARGET_SCORE:
			completed.emit(reward)
	else:
		lives -= 1
		_show_banner("Cuidado con " + bad_label)
		if lives <= 0:
			failed.emit()


func _show_banner(text: String) -> void:
	banner = text
	banner_time = 0.7


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, SCREEN), Color("#0a2540"))
	draw_rect(Rect2(0, 210, SCREEN.x, 870), Color("#147a9e"))
	draw_rect(Rect2(0, 1080, SCREEN.x, 200), Color("#8b5a2b"))

	for y in range(250, 1040, 50):
		draw_line(Vector2(0, y), Vector2(SCREEN.x, y + sin(float(y)) * 18.0), Color(1, 1, 1, 0.08), 3)

	_draw_text(Vector2(28, 42), title, 31, Color("#f4e4bc"))
	_draw_text(Vector2(28, 86), place, 18, Color("#48cae4"))
	_draw_text(Vector2(28, 125), objective, 17, Color.WHITE)
	_draw_text(Vector2(28, 165), "Meta: %d/%d   Vidas: %d   Recompensa: %s" % [score, TARGET_SCORE, lives, reward], 16, Color("#f4e4bc"))

	for item in items:
		if item["good"]:
			_draw_good_item(item["pos"])
		else:
			_draw_bad_item(item["pos"])

	_draw_ellipse(Rect2(player_x - 75, 1015, 150, 50), Color("#5c3d1e"))
	_draw_ellipse(Rect2(player_x - 58, 1000, 116, 48), player_color)
	_draw_text(Vector2(player_x - 42, 1088), "Atrapa", 17, Color("#f4e4bc"))

	if banner != "":
		draw_rect(Rect2(80, 610, 560, 80), Color(0, 0, 0, 0.72))
		_draw_text(Vector2(110, 662), banner, 23, Color("#f4e4bc"))


func _draw_good_item(pos: Vector2) -> void:
	draw_circle(pos, 27, good_color)
	draw_circle(pos, 12, Color("#f4e4bc"))


func _draw_bad_item(pos: Vector2) -> void:
	draw_circle(pos, 28, bad_color)
	draw_line(pos + Vector2(-14, -14), pos + Vector2(14, 14), Color("#e63946"), 5)
	draw_line(pos + Vector2(14, -14), pos + Vector2(-14, 14), Color("#e63946"), 5)


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
