extends Node2D

const SAVE_PATH := "user://flappy_pescador_manta.save"
const W := 1280.0
const H := 720.0
const HORIZON := 288.0
const PLAYER_X := 330.0
const PLAYER_RADIUS := 28.0
const GRAVITY := 1500.0
const FLAP_FORCE := -525.0
const NET_W := 78.0
const START_GAP := 220.0
const MIN_GAP := 165.0
const START_SPEED := 245.0
const MAX_SPEED := 405.0
const MAX_SCORE := 15
const MOVING_NET_SCORE := 10
const MOVING_NET_AMPLITUDE := 58.0
const LOBBY_SCENE := "res://escenas/lobby/lobby.tscn"

enum State { START, PLAYING, GAME_OVER, PAUSED, COMPLETE }

var state: State = State.START
var previous_state: State = State.START
var player_y := H * 0.48
var player_vy := 0.0
var player_angle := 0.0
var score := 0
var best_score := 0
var frame := 0.0
var spawn_timer := 0.0
var flash := 0.0
var nets: Array[Dictionary] = []
var splashes: Array[Dictionary] = []
var fishes: Array[Dictionary] = []
var gulls: Array[Dictionary] = []
var music_player: AudioStreamPlayer
var sfx_player: AudioStreamPlayer
var score_label: Label
var best_label: Label
var title_panel: Panel
var over_panel: Panel
var over_title: Label
var over_score: Label
var over_best: Label

func _ready() -> void:
	randomize()
	_load_best()
	_create_background_life()
	_create_audio()
	_create_ui()
	reset_game()

func _process(delta: float) -> void:
	frame += delta
	if flash > 0.0:
		flash = max(0.0, flash - delta * 2.5)
	if state == State.PLAYING:
		_update_game(delta)
	_update_background(delta)
	queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
	var pointer_pressed := false
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		pointer_pressed = touch.pressed
	elif event is InputEventMouseButton:
		var mouse := event as InputEventMouseButton
		pointer_pressed = mouse.pressed and mouse.button_index == MOUSE_BUTTON_LEFT
	if event.is_action_pressed("flap") or pointer_pressed:
		flap()
	if event.is_action_pressed("pause_game"):
		toggle_pause()

func reset_game() -> void:
	player_y = H * 0.48
	player_vy = 0.0
	player_angle = 0.0
	score = 0
	spawn_timer = 0.45
	nets.clear()
	splashes.clear()
	score_label.text = "0"
	_update_ui()

func flap() -> void:
	if state == State.START:
		state = State.PLAYING
		title_panel.visible = false
		over_panel.visible = false
		reset_game()
	elif state == State.GAME_OVER:
		state = State.PLAYING
		over_panel.visible = false
		reset_game()
	elif state != State.PLAYING:
		return
	player_vy = FLAP_FORCE
	player_angle = -0.38
	_spawn_splash(Vector2(PLAYER_X - 10.0, player_y + 24.0), 9)
	_play_sfx("click")

func toggle_pause() -> void:
	if state == State.PLAYING:
		previous_state = state
		state = State.PAUSED
		title_panel.visible = true
		_set_panel_text("Pausa", "La marea espera.\nToca Esc para continuar.")
	elif state == State.PAUSED:
		state = previous_state
		title_panel.visible = false

func _update_game(delta: float) -> void:
	player_vy += GRAVITY * delta
	player_y += player_vy * delta
	player_angle = clamp(lerpf(player_angle, player_vy * 0.0016, 0.11), -0.55, 0.95)
	spawn_timer -= delta
	if spawn_timer <= 0.0:
		_spawn_net()
		spawn_timer = lerpf(1.55, 1.17, min(float(score) / 22.0, 1.0))
	var speed := _current_speed()
	for net in nets:
		net["x"] = float(net["x"]) - speed * delta
		_update_net_motion(net)
		if not bool(net["passed"]) and float(net["x"]) + NET_W < PLAYER_X - PLAYER_RADIUS:
			net["passed"] = true
			score += 1
			score_label.text = str(score)
			_play_sfx("success")
			if score >= MAX_SCORE:
				_complete_game()
				return
	nets = nets.filter(func(net: Dictionary) -> bool: return float(net["x"]) > -NET_W - 20.0)
	_update_splashes(delta)
	if _hit_something():
		_game_over()

func _current_gap() -> float:
	return lerpf(START_GAP, MIN_GAP, min(float(score) / 28.0, 1.0))

func _current_speed() -> float:
	return lerpf(START_SPEED, MAX_SPEED, min(float(score) / 34.0, 1.0))

func _spawn_net() -> void:
	var gap := _current_gap()
	var center := randf_range(220.0, 1060.0) + sin(frame * 1.7 + float(score)) * 45.0
	center = clamp(center, 180.0 + gap * 0.5, W - 180.0 - gap * 0.5)
	var moving := score >= MOVING_NET_SCORE
	nets.append({
		"x": W + 35.0,
		"top_h": center - gap * 0.5,
		"bottom_y": center + gap * 0.5,
		"base_top_h": center - gap * 0.5,
		"base_bottom_y": center + gap * 0.5,
		"moving": moving,
		"motion_phase": randf() * TAU,
		"motion_speed": randf_range(1.6, 2.35),
		"passed": false,
		"phase": randf() * TAU
	})

func _update_net_motion(net: Dictionary) -> void:
	if not bool(net.get("moving", false)):
		return
	var offset := sin(frame * float(net["motion_speed"]) + float(net["motion_phase"])) * MOVING_NET_AMPLITUDE
	var base_top := float(net["base_top_h"])
	var base_bottom := float(net["base_bottom_y"])
	var gap := base_bottom - base_top
	var top_h := clampf(base_top + offset, 72.0, H - 120.0 - gap)
	net["top_h"] = top_h
	net["bottom_y"] = top_h + gap

func _hit_something() -> bool:
	if player_y - PLAYER_RADIUS < 12.0 or player_y + PLAYER_RADIUS > H - 58.0:
		return true
	var player := Rect2(PLAYER_X - PLAYER_RADIUS + 7.0, player_y - PLAYER_RADIUS + 5.0, PLAYER_RADIUS * 1.65, PLAYER_RADIUS * 1.65)
	for net in nets:
		var x := float(net["x"])
		var top_rect := Rect2(x, 0.0, NET_W, float(net["top_h"]))
		var bottom_y := float(net["bottom_y"])
		var bottom_rect := Rect2(x, bottom_y, NET_W, H - bottom_y - 48.0)
		if player.intersects(top_rect) or player.intersects(bottom_rect):
			return true
	return false

func _game_over() -> void:
	state = State.GAME_OVER
	flash = 1.0
	_spawn_splash(Vector2(PLAYER_X, player_y), 26)
	if score > best_score:
		best_score = score
		_save_best()
	over_title.text = "Nueva marca!" if score == best_score and score > 0 else "Naufragaste"
	over_score.text = "Puntuacion: %d" % score
	over_best.text = "Mejor marca: %d" % best_score
	over_panel.visible = true
	_update_ui()
	_play_sfx("fail")

func _complete_game() -> void:
	state = State.COMPLETE
	if score > best_score:
		best_score = score
		_save_best()
	over_title.text = "Ruta completada!"
	over_score.text = "Puntuacion: %d/%d" % [score, MAX_SCORE]
	over_best.text = "Volviendo al muelle..."
	over_panel.visible = true
	_update_ui()
	_play_sfx("success")
	await get_tree().create_timer(1.4).timeout
	if is_inside_tree():
		get_tree().change_scene_to_file(LOBBY_SCENE)

func _draw() -> void:
	_draw_sky()
	_draw_manta_coast()
	_draw_sea()
	_draw_fishes()
	_draw_gulls()
	_draw_nets()
	_draw_player()
	_draw_splashes()
	if flash > 0.0:
		draw_rect(Rect2(Vector2.ZERO, Vector2(W, H)), Color(1.0, 0.95, 0.65, flash * 0.23))

func _draw_sky() -> void:
	draw_rect(Rect2(0, 0, W, 120), Color("#35256f"))
	draw_rect(Rect2(0, 120, W, 100), Color("#8a4090"))
	draw_rect(Rect2(0, 220, W, HORIZON - 220), Color("#f27639"))
	draw_circle(Vector2(W - 140.0, HORIZON - 72.0), 62.0, Color(1.0, 0.67, 0.22, 0.22))
	draw_circle(Vector2(W - 140.0, HORIZON - 72.0), 32.0, Color("#ffd166"))
	for i in range(36):
		var x := fposmod(float(i * 97) + frame * 5.0, W)
		var y := 24.0 + fposmod(float(i * 53), 140.0)
		draw_circle(Vector2(x, y), 1.5 + float(i % 3) * 0.5, Color(1, 0.96, 0.82, 0.15))

func _draw_manta_coast() -> void:
	draw_rect(Rect2(0, HORIZON - 58.0, W, 64.0), Color("#d9a85c"))
	for i in range(13):
		var bx := fposmod(float(i * 74) - frame * 14.0, W + 80.0) - 40.0
		var bh := 35.0 + float((i * 19) % 62)
		draw_rect(Rect2(bx, HORIZON - 64.0 - bh, 46.0, bh), Color(0.08, 0.05, 0.15, 0.78))
	_draw_palm(Vector2(110, HORIZON - 28.0), 0.9, 1.0)
	_draw_palm(Vector2(W - 110, HORIZON - 26.0), 0.85, -1.0)

func _draw_palm(base: Vector2, scale: float, lean: float) -> void:
	var trunk := PackedVector2Array([
		base + Vector2(-8, 0) * scale,
		base + Vector2(lean * 15 - 4, -92) * scale,
		base + Vector2(lean * 15 + 8, -92) * scale,
		base + Vector2(8, 0) * scale
	])
	draw_colored_polygon(trunk, Color("#211126"))
	var top := base + Vector2(lean * 15, -94) * scale
	for i in range(6):
		var a := -PI + float(i) * PI / 5.0
		var end := top + Vector2(cos(a) * 68.0 * lean, sin(a) * 32.0 - 15.0) * scale
		draw_line(top, end, Color("#211126"), 9.0 * scale)

func _draw_sea() -> void:
	draw_rect(Rect2(0, HORIZON, W, H - HORIZON), Color("#196f85"))
	draw_rect(Rect2(0, HORIZON, W, 155), Color(0.18, 0.74, 0.78, 0.4))
	for layer in range(8):
		var y := HORIZON + 28.0 + float(layer) * 62.0
		var points := PackedVector2Array()
		for x in range(-20, int(W) + 42, 24):
			var yy := y + sin(float(x) * 0.035 + frame * (1.4 + layer * 0.16)) * (7.0 + layer)
			points.append(Vector2(float(x), yy))
		draw_polyline(points, Color(0.75, 1.0, 1.0, 0.16 + layer * 0.025), 4.0)

func _draw_fishes() -> void:
	for fish in fishes:
		var p: Vector2 = fish["pos"]
		var size := float(fish["size"])
		var color: Color = fish["color"]
		draw_circle(p, size, color)
		var tail := PackedVector2Array([p + Vector2(-size, 0), p + Vector2(-size * 1.8, -size * 0.75), p + Vector2(-size * 1.8, size * 0.75)])
		draw_colored_polygon(tail, color)

func _draw_gulls() -> void:
	for gull in gulls:
		var p: Vector2 = gull["pos"]
		draw_arc(p + Vector2(-9, 0), 14.0, PI * 0.08, PI * 0.9, 12, Color("#fff4d6"), 3.0)
		draw_arc(p + Vector2(9, 0), 14.0, PI * 0.1, PI * 0.92, 12, Color("#fff4d6"), 3.0)

func _draw_nets() -> void:
	for net in nets:
		_draw_net(float(net["x"]), 0.0, NET_W, float(net["top_h"]), true, float(net["phase"]))
		var by := float(net["bottom_y"])
		_draw_net(float(net["x"]), by, NET_W, H - by - 48.0, false, float(net["phase"]))

func _draw_net(x: float, y: float, w: float, h: float, from_top: bool, phase: float) -> void:
	if h <= 8.0:
		return
	var sway := sin(frame * 2.4 + phase) * 5.0
	var rect := Rect2(x + sway, y, w, h)
	draw_rect(rect, Color(0.04, 0.21, 0.28, 0.72))
	draw_rect(rect, Color("#40e0d0"), false, 4.0)
	for gx in range(14, int(w), 18):
		draw_line(Vector2(x + sway + gx, y), Vector2(x + sway + gx, y + h), Color(0.64, 1.0, 0.95, 0.45), 2.0)
	for gy in range(14, int(h), 18):
		draw_line(Vector2(x + sway, y + gy), Vector2(x + sway + w, y + gy), Color(0.64, 1.0, 0.95, 0.35), 2.0)
	var buoy_y := y + h - 18.0 if from_top else y + 18.0
	draw_circle(Vector2(x + sway + w * 0.5, buoy_y), 14.0, Color("#ffd166"))

func _draw_player() -> void:
	var p := Vector2(PLAYER_X, player_y)
	draw_set_transform(p, player_angle, Vector2.ONE)
	_draw_oval(Vector2.ZERO, Vector2(48, 19), Color("#f7b267"))
	draw_rect(Rect2(-38, -16, 76, 15), Color("#8d5524"))
	draw_circle(Vector2(-4, -36), 17.0, Color("#f4c095"))
	draw_rect(Rect2(-24, -58, 44, 17), Color("#ffd166"))
	draw_line(Vector2(19, -25), Vector2(53, -45), Color("#1d3557"), 5.0)
	draw_circle(Vector2(-12, -39), 3.0, Color("#1d3557"))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _draw_oval(center: Vector2, radius: Vector2, color: Color) -> void:
	var points := PackedVector2Array()
	for i in range(28):
		var a := TAU * float(i) / 28.0
		points.append(center + Vector2(cos(a) * radius.x, sin(a) * radius.y))
	draw_colored_polygon(points, color)

func _draw_splashes() -> void:
	for splash in splashes:
		draw_circle(splash["pos"], float(splash["r"]) * float(splash["life"]), splash["color"])

func _spawn_splash(origin: Vector2, amount: int) -> void:
	for i in range(amount):
		var angle := randf_range(-PI, 0.15)
		var speed := randf_range(90.0, 250.0)
		splashes.append({
			"pos": origin,
			"vel": Vector2(cos(angle), sin(angle)) * speed + Vector2(-50, -40),
			"life": 1.0,
			"r": randf_range(3.0, 8.0),
			"color": Color(0.7, 1.0, 1.0, randf_range(0.55, 0.9))
		})

func _update_splashes(delta: float) -> void:
	for splash in splashes:
		splash["pos"] = splash["pos"] + splash["vel"] * delta
		splash["vel"] = splash["vel"] + Vector2(0, 280.0) * delta
		splash["life"] = float(splash["life"]) - delta * 1.9
	splashes = splashes.filter(func(splash: Dictionary) -> bool: return float(splash["life"]) > 0.0)

func _create_background_life() -> void:
	for i in range(8):
		fishes.append({
			"pos": Vector2(randf_range(0, W), randf_range(HORIZON + 120, H - 80)),
			"speed": randf_range(28.0, 70.0),
			"size": randf_range(7.0, 16.0),
			"color": [Color("#ff8c42"), Color("#40e0d0"), Color("#ffd166"), Color("#ff6b9d")].pick_random()
		})
	for i in range(5):
		gulls.append({
			"pos": Vector2(randf_range(0, W), randf_range(48, 160)),
			"speed": randf_range(24.0, 54.0)
		})

func _update_background(delta: float) -> void:
	for fish in fishes:
		var p: Vector2 = fish["pos"]
		p.x -= float(fish["speed"]) * delta
		if p.x < -40.0:
			p.x = W + 40.0
			p.y = randf_range(HORIZON + 120, H - 80)
		fish["pos"] = p
	for gull in gulls:
		var p: Vector2 = gull["pos"]
		p.x += float(gull["speed"]) * delta
		if p.x > W + 45.0:
			p.x = -45.0
			p.y = randf_range(48, 160)
		gull["pos"] = p

func _create_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	score_label = Label.new()
	score_label.position = Vector2(0, 12)
	score_label.size = Vector2(W, 52)
	score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	score_label.add_theme_font_size_override("font_size", 58)
	score_label.add_theme_color_override("font_color", Color.WHITE)
	layer.add_child(score_label)
	best_label = Label.new()
	best_label.position = Vector2(24, 64)
	best_label.size = Vector2(W - 48, 38)
	best_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	best_label.add_theme_font_size_override("font_size", 24)
	best_label.add_theme_color_override("font_color", Color("#fff3b0"))
	layer.add_child(best_label)
	var pause_button := Button.new()
	pause_button.text = "II"
	pause_button.position = Vector2(W - 88, 12)
	pause_button.size = Vector2(66, 58)
	pause_button.add_theme_font_size_override("font_size", 24)
	pause_button.pressed.connect(Callable(self, "toggle_pause"))
	layer.add_child(pause_button)
	var flap_button := Button.new()
	flap_button.text = "SALTAR"
	flap_button.position = Vector2(W - 118.0, H - 86.0)
	flap_button.size = Vector2(100.0, 68.0)
	flap_button.add_theme_font_size_override("font_size", 22)
	flap_button.pressed.connect(Callable(self, "flap"))
	layer.add_child(flap_button)
	title_panel = _make_panel("Flappy Pescador", "Manta, Ecuador\nToca, clic o SALTAR para volar.\nEvita las redes en la bahia.", "Toca para comenzar")
	layer.add_child(title_panel)
	over_panel = _make_panel("", "", "")
	over_panel.visible = false
	layer.add_child(over_panel)
	over_title = over_panel.get_node("Box/Title") as Label
	over_score = over_panel.get_node("Box/Body") as Label
	over_best = over_panel.get_node("Box/Hint") as Label

func _make_panel(title: String, body: String, hint_text: String) -> Panel:
	var panel := Panel.new()
	panel.position = Vector2(W * 0.5 - 290.0, H * 0.5 - 165.0)
	panel.size = Vector2(580, 330)
	var box := VBoxContainer.new()
	box.name = "Box"
	box.position = Vector2(36, 34)
	box.size = Vector2(508, 360)
	box.add_theme_constant_override("separation", 18)
	panel.add_child(box)
	var title_label := Label.new()
	title_label.name = "Title"
	title_label.text = title
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 42)
	title_label.add_theme_color_override("font_color", Color("#ffd166"))
	box.add_child(title_label)
	var body_label := Label.new()
	body_label.name = "Body"
	body_label.text = body
	body_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body_label.add_theme_font_size_override("font_size", 25)
	body_label.add_theme_color_override("font_color", Color("#e8f7ff"))
	box.add_child(body_label)
	var hint := Label.new()
	hint.name = "Hint"
	hint.text = hint_text
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 23)
	hint.add_theme_color_override("font_color", Color("#40e0d0"))
	box.add_child(hint)
	return panel

func _set_panel_text(title: String, body: String) -> void:
	var panel_title := title_panel.get_node("Box/Title") as Label
	var panel_body := title_panel.get_node("Box/Body") as Label
	var panel_hint := title_panel.get_node("Box/Hint") as Label
	panel_title.text = title
	panel_body.text = body
	panel_hint.text = "Esc para continuar"

func _update_ui() -> void:
	best_label.text = "Mejor marca: %d" % best_score

func _create_audio() -> void:
	music_player = AudioStreamPlayer.new()
	sfx_player = AudioStreamPlayer.new()
	add_child(music_player)
	add_child(sfx_player)
	music_player.stream = _make_tone(220.0, 2.4, 0.06, true)
	music_player.volume_db = -20.0
	music_player.play()

func _play_sfx(kind: String) -> void:
	var freq := 660.0
	var duration := 0.08
	var volume := 0.18
	if kind == "success":
		freq = 880.0
		duration = 0.18
		volume = 0.22
	elif kind == "fail":
		freq = 180.0
		duration = 0.25
		volume = 0.20
	sfx_player.stream = _make_tone(freq, duration, volume, false)
	sfx_player.volume_db = -9.0
	sfx_player.play()

func _make_tone(freq: float, seconds: float, volume: float, loop: bool) -> AudioStreamWAV:
	var rate := 22050
	var sample_count := int(float(rate) * seconds)
	var data := PackedByteArray()
	data.resize(sample_count * 2)
	for i in range(sample_count):
		var fade_in: float = minf(1.0, float(i) / 800.0)
		var fade_out: float = minf(1.0, float(sample_count - i) / 1200.0)
		var env: float = fade_in * fade_out
		var sample: int = int(sin(TAU * freq * float(i) / float(rate)) * 32767.0 * volume * env)
		if sample < 0:
			sample = 65536 + sample
		data[i * 2] = sample & 0xff
		data[i * 2 + 1] = (sample >> 8) & 0xff
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = rate
	wav.stereo = false
	wav.data = data
	if loop:
		wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
		wav.loop_end = sample_count
	return wav

func _load_best() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file != null:
		best_score = int(file.get_as_text())

func _save_best() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file != null:
		file.store_string(str(best_score))
