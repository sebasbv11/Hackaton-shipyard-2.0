extends CharacterBody2D


const SPEED: float         = 240.0
const JUMP_VELOCITY: float = -680.0
const GRAVITY: float       = 1200.0

var is_alive: bool       = true
var control_activo: bool = true
var inmune: bool         = false
var anim_time: float     = 0.0

# Dash / Turbo
var velocidad_actual: float = 210.0
var esta_en_dash: bool      = false
var dash_timer: float       = 0.0

var particulas_dash: Array = []

var combo_label: Label = null

@onready var visual: Node2D    = $Visual
@onready var anim_timer: Timer = $AnimTimer

func _ready() -> void:
	add_to_group("player")
	add_to_group("jugador")
	if anim_timer:
		anim_timer.timeout.connect(_tick_anim)
		anim_timer.start()

	if GameManager.has_signal("combo_changed"):
		GameManager.combo_changed.connect(_on_combo_changed)

	_crear_combo_label()

func _crear_combo_label() -> void:
	combo_label = Label.new()
	combo_label.text = ""
	combo_label.position = Vector2(-30, -95)
	combo_label.add_theme_font_size_override("font_size", 22)
	combo_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.0, 0.0))
	combo_label.z_index = 10
	add_child(combo_label)

func _on_combo_changed(nivel: int, multiplicador: int) -> void:
	if not is_instance_valid(combo_label):
		return
	if nivel == 0:
		# Apagar el label suavemente
		var tw = create_tween()
		tw.tween_property(combo_label, "modulate:a", 0.0, 0.3)
		return
	
	var textos := ["", "x2 COMBO!", "x3 COMBO!", "x4 MAX COMBO!"]
	var colores := [Color.WHITE, Color(0.2, 0.8, 1.0), Color(1.0, 0.5, 0.0), Color(1.0, 0.1, 0.1)]
	combo_label.text = textos[nivel]
	combo_label.add_theme_color_override("font_color", colores[nivel])
	combo_label.modulate.a = 1.0
	combo_label.scale = Vector2(1.5, 1.5)
	var tw = create_tween()
	tw.tween_property(combo_label, "scale", Vector2(1.0, 1.0), 0.2)

func _physics_process(delta: float) -> void:
	if not is_alive:
		return
	anim_time += delta

	# Temporizador del Dash
	if esta_en_dash:
		dash_timer -= delta
		_emitir_particula_dash()
		if dash_timer <= 0:
			esta_en_dash = false
			velocidad_actual = SPEED

	for p in particulas_dash.duplicate():
		if not is_instance_valid(p) or p.modulate.a <= 0.05:
			if is_instance_valid(p):
				p.queue_free()
			particulas_dash.erase(p)

	if not is_on_floor():
		velocity.y += GRAVITY * delta
	else:
		velocity.y = 0

	if control_activo:
		velocity.x = velocidad_actual

		# LAPTOP: Salto (Espacio / Arriba)
		if (Input.is_action_just_pressed("ui_accept") or
			Input.is_action_just_pressed("ui_up")) and is_on_floor():
			velocity.y = JUMP_VELOCITY

		# LAPTOP: Dash (Shift o C)
		if Input.is_key_pressed(KEY_SHIFT) or Input.is_key_pressed(KEY_C):
			activar_dash()
	else:
		velocity.x = 0

	move_and_slide()

	# Squash & stretch
	if visual:
		if not is_on_floor():
			visual.scale = Vector2(0.83, 1.17)
		else:
			var s = 1.0 + sin(anim_time * 6.2) * 0.025
			visual.scale = Vector2(s, 1.0 / s)

func _emitir_particula_dash() -> void:
	var p = Polygon2D.new()
	p.polygon = PackedVector2Array([
		Vector2(-8, -10), Vector2(8, -10),
		Vector2(12, 0), Vector2(8, 10), Vector2(-8, 10)
	])
	var col = Color(0.3, 0.8, 1.0, 0.7) if not GameManager.combo_activo else Color(1.0, 0.5, 0.0, 0.8)
	p.color = col
	p.global_position = global_position
	p.z_index = -1
	get_parent().add_child(p)
	particulas_dash.append(p)
	var tw = create_tween()
	tw.tween_property(p, "modulate:a", 0.0, 0.25)
	tw.tween_property(p, "scale", Vector2(2.0, 0.3), 0.25)

func activar_dash() -> void:
	if not esta_en_dash:
		esta_en_dash = true
		dash_timer = 0.25
		velocidad_actual = SPEED * 2.3
		# Flash visual al activar dash
		if visual:
			var tw = create_tween()
			tw.tween_property(visual, "modulate", Color(0.4, 0.9, 1.0, 1.0), 0.05)
			tw.tween_property(visual, "modulate", Color(1, 1, 1, 1), 0.15)

func _tick_anim() -> void:
	pass

func detener_para_dialogo() -> void:
	control_activo = false
	velocidad_actual = 0

func recibir_dano() -> void:
	if esta_en_dash:
		return

	if inmune or not is_alive:
		return
	inmune = true
	GameManager.perder_vida()

	var hud = get_tree().get_root().find_child("VidasLabel", true, false)
	if hud:
		var v = GameManager.vidas
		var txt = ""
		for i in 5:
			txt += "V" if i < v else "-"
		hud.text = txt

	if GameManager.vidas <= 0:
		is_alive = false
		var tw = create_tween()
		if visual:
			tw.tween_property(visual, "modulate:a", 0.0, 0.5)
		await tw.finished
		get_tree().change_scene_to_file("res://modulos/minijuego_1/escenas/minijuego_1/game_over.tscn")
		return

	for i in 5:
		if visual:
			visual.modulate = Color(1, 0.2, 0.2, 0.5)
		await get_tree().create_timer(0.12).timeout
		if visual:
			visual.modulate = Color(1, 1, 1, 1)
		await get_tree().create_timer(0.12).timeout

	await get_tree().create_timer(0.5).timeout
	inmune = false

func golpear() -> void:
	recibir_dano()
