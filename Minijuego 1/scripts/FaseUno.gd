extends Node2D

# ══════════════════════════════════════════════════════════════════
#  FaseUno.gd — v6 COMPLETO
#  San Lorenzo: paisaje de montañas en capas (img 2)
#  Pacoche:     plataformas flotantes + huecos (img 1)
#  Santa Mar.:  playa tropical colorida low-poly (img 3)
#  Manta Urb.:  ciudad nocturna (igual, mejorada)
#  + Sistema de Combo en HUD
#  + Escalado vertical (plataformas a distintas alturas)
# ══════════════════════════════════════════════════════════════════

@onready var fade_overlay: ColorRect = $FadeOverlay
@onready var player                  = $Player
@onready var camera: Camera2D        = $Player/Camera2D
@onready var hud: CanvasLayer        = $HUD
@onready var score_lbl: Label        = $HUD/ScoreLabel
@onready var vidas_hud: Node2D       = $HUD/VidaHUD
@onready var zona_lbl: Label         = $HUD/ZonaLabel
@onready var gemas_lbl: Label        = $HUD/GemasLabel
@onready var msg_panel: ColorRect    = $HUD/MsgPanel
@onready var msg_lbl: Label          = $HUD/MsgPanel/MsgLabel
@onready var cielo_base: ColorRect   = $BG/Cielo/CieloBase

@export var escena_obstaculo: PackedScene
@export var escena_concha: PackedScene

const ZONAS_X    := [0.0, 3500.0, 7000.0, 10500.0]
const ZONA_ANCHO := 3500.0

const ZONAS_INFO := [
	{"nombre": "San Lorenzo",     "subtitulo": "El Faro de los Navegantes",
	 "cielo": Color(0.45, 0.72, 0.92, 1), "tierra": Color(0.30, 0.48, 0.18, 1),
	 "montana": Color(0.22, 0.42, 0.18, 1)},
	{"nombre": "Bosque de Pacoche","subtitulo": "Selva Tropical Protegida",
	 "cielo": Color(0.18, 0.35, 0.22, 1), "tierra": Color(0.14, 0.28, 0.10, 1),
	 "montana": Color(0.10, 0.22, 0.08, 1)},
	{"nombre": "Santa Marianita",  "subtitulo": "Playa del Atardecer",
	 "cielo": Color(0.88, 0.48, 0.18, 1), "tierra": Color(0.72, 0.58, 0.32, 1),
	 "montana": Color(0.55, 0.35, 0.15, 1)},
	{"nombre": "Manta Urbano",     "subtitulo": "Megaparque y Haz de Luz",
	 "cielo": Color(0.06, 0.08, 0.22, 1), "tierra": Color(0.20, 0.20, 0.25, 1),
	 "montana": Color(0.14, 0.14, 0.18, 1)},
]

var zona_anterior: int   = -1
var corazones: Array     = []
var en_transicion: bool  = false
var tiempo_acumulado: float = 0.0
var meta_alcanzada: bool = false
var gemas_actuales: int  = 0
var ultima_x_spawn_gema: float      = 0.0
var ultima_x_spawn_obstaculo: float = 0.0
var esta_muriendo: bool=false


# 🌟 Label de combo en HUD
var combo_hud_label: Label = null

func _ready() -> void:
	GameManager.reset()
	GameManager.score_changed.connect(_on_score_changed)
	GameManager.vidas_changed.connect(_on_vidas_changed)
	GameManager.gema_recolectada.connect(_on_gema_recolectada)
	GameManager.zona_completada.connect(_on_zona_completada)
	GameManager.combo_changed.connect(_on_combo_changed)

	for i in 5:
		var v = vidas_hud.get_node_or_null("Vida%d" % (i+1))
		if v:
			corazones.append(v)
	_actualizar_corazones(5)

	# 🌟 Crear HUD de Combo dinámicamente
	_crear_combo_hud()

	_construir_mundo()

	if player:
		ultima_x_spawn_gema      = player.position.x
		ultima_x_spawn_obstaculo = player.position.x

	fade_overlay.modulate.a = 1.0
	var tw = create_tween()
	tw.tween_property(fade_overlay, "modulate:a", 0.0, 1.0)
	await tw.finished

	_mostrar_mensaje(ZONAS_INFO[0].nombre + "\n" + ZONAS_INFO[0].subtitulo, 2.5)
	await get_tree().create_timer(2.5).timeout

	camera.limit_left = 0

func _crear_combo_hud() -> void:
	combo_hud_label = Label.new()
	combo_hud_label.text = ""
	combo_hud_label.position = Vector2(640 - 100, 60)
	combo_hud_label.add_theme_font_size_override("font_size", 26)
	combo_hud_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.0, 0.0))
	combo_hud_label.modulate.a = 0.0
	hud.add_child(combo_hud_label)


func _on_combo_changed(nivel: int, multiplicador: int) -> void:
	if not is_instance_valid(combo_hud_label):
		return
	if nivel == 0:
		var tw = create_tween()
		tw.tween_property(combo_hud_label, "modulate:a", 0.0, 0.4)
		return

	var textos := ["", "⚡ COMBO x2", "🔥 COMBO x3", "💥 COMBO x4 MAX!"]
	var colores := [Color.WHITE,
		Color(0.2, 0.9, 1.0, 1.0),
		Color(1.0, 0.55, 0.0, 1.0),
		Color(1.0, 0.15, 0.15, 1.0)]

	combo_hud_label.text = textos[nivel]
	combo_hud_label.add_theme_color_override("font_color", colores[nivel])
	combo_hud_label.modulate.a = 1.0
	combo_hud_label.scale = Vector2(1.4, 1.4)

	var tw = create_tween()
	tw.tween_property(combo_hud_label, "scale", Vector2(1.0, 1.0), 0.2)
	# Parpadeo en combo x4
	if nivel == 3:
		var tw2 = create_tween().set_loops(99)
		tw2.tween_property(combo_hud_label, "modulate:a", 0.5, 0.25)
		tw2.tween_property(combo_hud_label, "modulate:a", 1.0, 0.25)



func _process(delta: float) -> void:
	# 1. Seguridad: Si el jugador no existe, salimos
	if not is_instance_valid(player):
		return
	
	tiempo_acumulado += delta

	# 2. Lógica de cámara
	if player.position.x - 280 > camera.limit_left:
		camera.limit_left = int(player.position.x) - 280
	
	# 3. VERIFICACIÓN ÚNICA DE CAÍDA AL VACÍO
	if player.position.y > 750:
		_ejecutar_game_over()
		return # Detenemos todo el proceso aquí si el jugador cae

	# 4. Spawners (solo si estamos vivos y no en transición)
	if not en_transicion:
		if player.position.x > ultima_x_spawn_gema + 380.0:
			ultima_x_spawn_gema = player.position.x
			_spawn_gema()
		if player.position.x > ultima_x_spawn_obstaculo + 750.0:
			ultima_x_spawn_obstaculo = player.position.x
			_spawn_obstaculo()

	# 5. Lógica de zonas
	if GameManager.zona_actual < ZONAS_X.size():
		var x_limite = ZONAS_X[GameManager.zona_actual] + ZONA_ANCHO
		if not en_transicion and player.position.x > x_limite - 50:
			player.position.x = x_limite - 50

	_actualizar_entorno()
	queue_redraw()
	
	
func _ejecutar_game_over() -> void:
	# Verificamos si existe antes de borrar
	if is_instance_valid(player):
		player.queue_free()
	
	GameManager.vidas = 0
	
	# CRÍTICO: Cambiar a la escena de Game Over
	# Asegúrate de que la ruta sea la correcta en tu proyecto
	get_tree().change_scene_to_file("res://scenes/game_over.tscn")
	
	print("Game Over ejecutado y transición iniciada.")
		

func _actualizar_entorno() -> void:
	var z = GameManager.zona_actual
	if z == zona_anterior or z >= ZONAS_INFO.size():
		return
	zona_anterior = z
	var info = ZONAS_INFO[z]
	var tw = create_tween()
	tw.tween_property(cielo_base, "color", info.cielo, 1.5)
	zona_lbl.text  = info.nombre
	gemas_lbl.text = "Gemas: 0/5"

# ══════════════════════════════════════════════════════════════════
#  CONSTRUCCIÓN DEL MUNDO
# ══════════════════════════════════════════════════════════════════
func _construir_mundo() -> void:
	_zona_san_lorenzo()
	_zona_pacoche()
	_zona_santa_marianita()
	_zona_manta_urbano()
	_crear_suelos()

func _crear_suelos() -> void:
	var muro_izq = StaticBody2D.new()
	var mc_izq = CollisionShape2D.new()
	var mf_izq = RectangleShape2D.new()
	mf_izq.size = Vector2(40, 900)
	mc_izq.shape = mf_izq
	muro_izq.position = Vector2(-30, 360)
	muro_izq.add_child(mc_izq)
	add_child(muro_izq)

	var muro_der = StaticBody2D.new()
	var mc_der = CollisionShape2D.new()
	var mf_der = RectangleShape2D.new()
	mf_der.size = Vector2(40, 900)
	mc_der.shape = mf_der
	muro_der.position = Vector2(ZONAS_X[3] + ZONA_ANCHO + 100, 360)
	muro_der.add_child(mc_der)
	add_child(muro_der)

# ─── ZONA 1: SAN LORENZO ──────────────────────────────────────────
# Inspirada en imagen 2: montañas en capas, árboles de pinos, cielo azul
func _zona_san_lorenzo() -> void:
	var ox = ZONAS_X[0]

	# === FONDO: CIELO CON GRADIENTE ===
	var cielo = _poligono(PackedVector2Array([
		Vector2(ox - 100, 0), Vector2(ox + ZONA_ANCHO + 100, 0),
		Vector2(ox + ZONA_ANCHO + 100, 600), Vector2(ox - 100, 600)
	]), Color(0.45, 0.72, 0.92, 1), -10)
	cielo.vertex_colors = PackedColorArray([
		Color(0.38, 0.62, 0.92, 1), Color(0.38, 0.62, 0.92, 1),
		Color(0.62, 0.84, 0.98, 1), Color(0.62, 0.84, 0.98, 1)
	])
	add_child(cielo)

	# === NUBES ===
	_dibujar_nubes_san_lorenzo(ox)

	# === CAPA 1: MONTAÑAS LEJANAS (MÁS CLARAS, FONDO) ===
	var montana_lejos = PackedVector2Array([
		Vector2(ox - 100, 600),
		Vector2(ox + 200, 420), Vector2(ox + 450, 480),
		Vector2(ox + 700, 340), Vector2(ox + 900, 400),
		Vector2(ox + 1100, 310), Vector2(ox + 1350, 380),
		Vector2(ox + 1600, 290), Vector2(ox + 1800, 360),
		Vector2(ox + 2000, 320), Vector2(ox + 2250, 400),
		Vector2(ox + 2500, 330), Vector2(ox + 2700, 410),
		Vector2(ox + 2900, 350), Vector2(ox + 3100, 430),
		Vector2(ox + ZONA_ANCHO + 100, 600)
	])
	add_child(_poligono(montana_lejos, Color(0.58, 0.72, 0.62, 0.8), -8))

	# Nieve en picos lejanos
	for pico in [[ox+700,340],[ox+1100,310],[ox+1600,290],[ox+2000,320]]:
		var nieve = _poligono(PackedVector2Array([
			Vector2(pico[0] - 30, pico[1] + 40),
			Vector2(pico[0] + 30, pico[1] + 40),
			Vector2(pico[0] + 8, pico[1] + 8),
			Vector2(pico[0], pico[1]),
			Vector2(pico[0] - 8, pico[1] + 8)
		]), Color(0.92, 0.95, 0.98, 0.85), -7)
		add_child(nieve)

	# === CAPA 2: COLINAS MEDIAS CON PINOS ===
	var colinas = PackedVector2Array([
		Vector2(ox - 100, 600),
		Vector2(ox + 150, 510), Vector2(ox + 400, 540),
		Vector2(ox + 600, 490), Vector2(ox + 850, 520),
		Vector2(ox + 1050, 475), Vector2(ox + 1300, 505),
		Vector2(ox + 1500, 480), Vector2(ox + 1750, 510),
		Vector2(ox + 1950, 490), Vector2(ox + 2200, 520),
		Vector2(ox + 2450, 495), Vector2(ox + 2650, 515),
		Vector2(ox + 2850, 500), Vector2(ox + 3100, 525),
		Vector2(ox + ZONA_ANCHO + 100, 600)
	])
	add_child(_poligono(colinas, Color(0.28, 0.52, 0.22, 0.9), -6))

	# === CAPA 3: PINOS en la colina media ===
	for px in [ox+250, ox+480, ox+720, ox+960, ox+1180, ox+1420,
			   ox+1680, ox+1920, ox+2180, ox+2420, ox+2680, ox+2950]:
		_dibujar_pino(Vector2(px, 510), -5)

	# === CAPA 4: TERRENO BASE (con física) ===
	_crear_bloque_suelo_fisico(ox - 500, ox + ZONA_ANCHO + 500, 600, Color(0.25, 0.45, 0.15, 1))

	# Capa de hierba
	var hierba = _poligono(PackedVector2Array([
		Vector2(ox - 500, 600), Vector2(ox + ZONA_ANCHO + 500, 600),
		Vector2(ox + ZONA_ANCHO + 500, 612), Vector2(ox - 500, 612)
	]), Color(0.38, 0.68, 0.22, 1), -1)
	add_child(hierba)

	# === ELEMENTOS ICÓNICOS ===
	_dibujar_faro(Vector2(ox + 500, 600))
	_dibujar_palmera(Vector2(ox + 800, 600))
	_dibujar_palmera(Vector2(ox + 1500, 600))
	_dibujar_palmera(Vector2(ox + 2200, 600))
	_letrero_zona(Vector2(ox + 150, 530), "SAN LORENZO", Color(0.08, 0.22, 0.55, 1))

func _dibujar_nubes_san_lorenzo(ox: float) -> void:
	var posiciones = [
		[ox + 300, 80], [ox + 700, 55], [ox + 1200, 95],
		[ox + 1800, 65], [ox + 2300, 85], [ox + 2900, 70]
	]
	for pos in posiciones:
		_dibujar_nube(Vector2(pos[0], pos[1]), randf_range(0.8, 1.3))

func _dibujar_nube(pos: Vector2, escala: float) -> void:
	var n = Node2D.new()
	n.position = pos
	n.z_index = -6
	var radios = [[0, 0, 38], [-35, 10, 28], [35, 10, 28], [-20, 15, 22], [20, 15, 22]]
	for r in radios:
		var pts = PackedVector2Array()
		for i in 16:
			var ang = i * TAU / 16
			pts.append(Vector2(r[0] + cos(ang) * r[2] * escala, r[1] + sin(ang) * r[2] * escala * 0.65))
		n.add_child(_poligono(pts, Color(0.96, 0.97, 0.99, 0.92)))
	add_child(n)

func _dibujar_pino(pos: Vector2, zi: int = 0) -> void:
	var n = Node2D.new()
	n.position = pos
	n.z_index = zi
	# Tronco
	n.add_child(_poligono(PackedVector2Array([
		Vector2(-4, 0), Vector2(4, 0), Vector2(3, -20), Vector2(-3, -20)
	]), Color(0.35, 0.22, 0.10, 1)))
	# 3 capas triangulares del pino
	var alturas = [[0, -25, 32], [-18, -45, 26], [-35, -62, 20]]
	for a in alturas:
		n.add_child(_poligono(PackedVector2Array([
			Vector2(-a[2], a[0]), Vector2(a[2], a[0]), Vector2(0, a[1])
		]), Color(0.12, 0.38, 0.12, 1)))
	add_child(n)

# ─── ZONA 2: PACOCHE ──────────────────────────────────────────────
# Inspirada en imagen 1: plataformas a distintas alturas, huecos, selva
func _zona_pacoche() -> void:
	var ox = ZONAS_X[1]

	# Fondo de selva
	var fondo = _poligono(PackedVector2Array([
		Vector2(ox - 50, 0), Vector2(ox + ZONA_ANCHO + 50, 0),
		Vector2(ox + ZONA_ANCHO + 50, 700), Vector2(ox - 50, 700)
	]), Color(0.06, 0.18, 0.10, 1), -10)
	fondo.vertex_colors = PackedColorArray([
		Color(0.20, 0.42, 0.26, 1), Color(0.20, 0.42, 0.26, 1),
		Color(0.04, 0.12, 0.06, 1), Color(0.04, 0.12, 0.06, 1)
	])
	add_child(fondo)

	# Siluetas de árboles lejanos (fondo)
	for i in range(8):
		var sx = ox + 80 + i * 420
		var alt = randf_range(200, 320)
		var sil = _poligono(PackedVector2Array([
			Vector2(sx - 55, 600), Vector2(sx - 18, int(600 - alt)),
			Vector2(sx + 18, int(600 - alt)), Vector2(sx + 55, 600)
		]), Color(0.06, 0.20, 0.08, 0.5), -9)
		add_child(sil)

	# ================================================================
	# SISTEMA DE PLATAFORMAS con huecos (como imagen 1)
	# ================================================================
	# Plataforma 1: Entrada larga
	_crear_plataforma_pacoche(ox - 50, ox + 700, 600)

	# HUECO 1 (pequeño, fácil de saltar)
	# Plataforma 2: Media altura
	_crear_plataforma_pacoche(ox + 850, ox + 1400, 560)

	# HUECO 2
	# Plataforma 3: Alta (hay que saltar bien)
	_crear_plataforma_pacoche(ox + 1550, ox + 2000, 510)

	# HUECO 3 (grande, necesitas dash o doble salto)
	# Plataforma 4: Baja de nuevo
	_crear_plataforma_pacoche(ox + 2250, ox + 2750, 570)

	# HUECO 4
	# Plataforma 5: Salida
	_crear_plataforma_pacoche(ox + 2900, ox + ZONA_ANCHO + 50, 600)

	# === ÁRBOLES PRINCIPALES ===
	_dibujar_arbol_selva(Vector2(ox + 300, 600))
	_dibujar_arbol_selva(Vector2(ox + 1100, 560))
	_dibujar_arbol_selva(Vector2(ox + 1750, 510))
	_dibujar_arbol_selva(Vector2(ox + 2400, 570))
	_dibujar_arbol_selva(Vector2(ox + 3100, 600))

	# === LIANAS ===
	_dibujar_liana(Vector2(ox + 500, 160))
	_dibujar_liana(Vector2(ox + 1200, 140))
	_dibujar_liana(Vector2(ox + 1900, 130))
	_dibujar_liana(Vector2(ox + 2600, 155))

	# === MONOS ===
	_dibujar_mono(Vector2(ox + 650, 460))
	_dibujar_mono(Vector2(ox + 1450, 400))
	_dibujar_mono(Vector2(ox + 2100, 390))

	# === RAYOS DE LUZ que filtran por el dosel ===
	for i in 5:
		var lx = ox + 300 + i * 600
		var rayo = _poligono(PackedVector2Array([
			Vector2(lx, 0), Vector2(lx + 30, 0),
			Vector2(lx + 80, 600), Vector2(lx + 50, 600)
		]), Color(0.65, 0.88, 0.45, 0.07), -4)
		add_child(rayo)

	_letrero_zona(Vector2(ox + 150, 530), "RESERVA PACOCHE", Color(0.35, 0.65, 0.20, 1))

func _crear_plataforma_pacoche(x_inicio: float, x_fin: float, altura_y: float) -> void:
	# Suelo físico de tierra/raíces
	_crear_bloque_suelo_fisico(x_inicio, x_fin, altura_y, Color(0.18, 0.12, 0.06, 1))

	# Capa de musgo/hierba encima
	var musgo = _poligono(PackedVector2Array([
		Vector2(x_inicio, altura_y), Vector2(x_fin, altura_y),
		Vector2(x_fin, altura_y + 14), Vector2(x_inicio, altura_y + 14)
	]), Color(0.22, 0.52, 0.12, 1), -1)
	add_child(musgo)

	# Borde de raíces (decorativo)
	var raiz_izq = _poligono(PackedVector2Array([
		Vector2(x_inicio, altura_y),
		Vector2(x_inicio + 18, altura_y),
		Vector2(x_inicio + 12, altura_y + 28),
		Vector2(x_inicio - 5, altura_y + 22)
	]), Color(0.15, 0.09, 0.04, 1), -1)
	add_child(raiz_izq)

	var raiz_der = _poligono(PackedVector2Array([
		Vector2(x_fin, altura_y),
		Vector2(x_fin - 18, altura_y),
		Vector2(x_fin - 12, altura_y + 28),
		Vector2(x_fin + 5, altura_y + 22)
	]), Color(0.15, 0.09, 0.04, 1), -1)
	add_child(raiz_der)

	# Hongos/setas decorativos encima (como imagen 1)
	var num_hongos = int((x_fin - x_inicio) / 180)
	for i in num_hongos:
		var hx = x_inicio + 90 + i * 180
		_dibujar_hongo_pacoche(Vector2(hx, altura_y))

func _dibujar_hongo_pacoche(pos: Vector2) -> void:
	var n = Node2D.new()
	n.position = pos
	n.z_index = 1
	# Tallo
	n.add_child(_poligono(PackedVector2Array([
		Vector2(-4, 0), Vector2(4, 0), Vector2(3, -16), Vector2(-3, -16)
	]), Color(0.75, 0.68, 0.55, 1)))
	# Sombrero
	n.add_child(_poligono(PackedVector2Array([
		Vector2(-14, -16), Vector2(14, -16),
		Vector2(10, -30), Vector2(0, -35), Vector2(-10, -30)
	]), Color(0.72, 0.18, 0.08, 1)))
	# Puntos blancos
	for px in [-5, 4]:
		n.add_child(_poligono(PackedVector2Array([
			Vector2(px, -22), Vector2(px + 4, -22),
			Vector2(px + 4, -18), Vector2(px, -18)
		]), Color(0.95, 0.92, 0.88, 1)))
	add_child(n)

# ─── ZONA 3: SANTA MARIANITA ──────────────────────────────────────
# Inspirada en imagen 3: playa tropical, palmeras low-poly, agua turquesa
func _zona_santa_marianita() -> void:
	var ox = ZONAS_X[2]

	# === CIELO TROPICAL ===
	var cielo_sm = _poligono(PackedVector2Array([
		Vector2(ox, 0), Vector2(ox + ZONA_ANCHO, 0),
		Vector2(ox + ZONA_ANCHO, 600), Vector2(ox, 600)
	]), Color(0.38, 0.72, 0.95, 1), -10)
	cielo_sm.vertex_colors = PackedColorArray([
		Color(0.38, 0.72, 0.95, 1), Color(0.38, 0.72, 0.95, 1),
		Color(0.62, 0.84, 0.78, 1), Color(0.62, 0.84, 0.78, 1)
	])
	add_child(cielo_sm)

	# === SOL BRILLANTE ===
	_dibujar_sol_tropical(Vector2(ox + 2800, 120))

	# === NUBES BLANCAS ===
	_dibujar_nube(Vector2(ox + 400, 90), 1.1)
	_dibujar_nube(Vector2(ox + 1200, 70), 0.9)
	_dibujar_nube(Vector2(ox + 2100, 100), 1.2)

	# === MAR TURQUESA (capas) ===
	# Mar lejano (horizonte)
	var mar_lejos = _poligono(PackedVector2Array([
		Vector2(ox, 300), Vector2(ox + ZONA_ANCHO, 300),
		Vector2(ox + ZONA_ANCHO, 430), Vector2(ox, 430)
	]), Color(0.20, 0.62, 0.78, 0.55), -7)
	add_child(mar_lejos)

	# Mar medio
	var mar_medio = _poligono(PackedVector2Array([
		Vector2(ox, 380), Vector2(ox + ZONA_ANCHO, 380),
		Vector2(ox + ZONA_ANCHO, 490), Vector2(ox, 490)
	]), Color(0.22, 0.70, 0.82, 0.65), -6)
	add_child(mar_medio)

	# Olas
	for i in range(5):
		var ola_y = 350 + i * 40
		_dibujar_ola_tropical(ox, ola_y, i)

	# === ARENA con gradiente ===
	var arena = _poligono(PackedVector2Array([
		Vector2(ox, 490), Vector2(ox + ZONA_ANCHO, 490),
		Vector2(ox + ZONA_ANCHO, 700), Vector2(ox, 700)
	]), Color(0.95, 0.85, 0.60, 1), -5)
	arena.vertex_colors = PackedColorArray([
		Color(0.88, 0.80, 0.55, 1), Color(0.88, 0.80, 0.55, 1),
		Color(0.78, 0.68, 0.42, 1), Color(0.78, 0.68, 0.42, 1)
	])
	add_child(arena)

	# === SUELOS FÍSICOS ESCALONADOS ===
	_crear_bloque_suelo_fisico(ox, ox + 800, 600, Color(0.92, 0.82, 0.58, 1))
	_crear_bloque_suelo_fisico(ox + 800, ox + 900, 570, Color(0.90, 0.80, 0.55, 1))  # Rampa
	_crear_bloque_suelo_fisico(ox + 900, ox + 2100, 530, Color(0.95, 0.85, 0.60, 1))  # Duna alta
	_crear_bloque_suelo_fisico(ox + 2100, ox + 2200, 560, Color(0.90, 0.80, 0.55, 1))  # Bajada
	_crear_bloque_suelo_fisico(ox + 2200, ox + ZONA_ANCHO, 600, Color(0.92, 0.82, 0.58, 1))

	# Linea de orilla
	var orilla = _poligono(PackedVector2Array([
		Vector2(ox, 488), Vector2(ox + ZONA_ANCHO, 488),
		Vector2(ox + ZONA_ANCHO, 495), Vector2(ox, 495)
	]), Color(0.75, 0.92, 0.96, 0.55), -4)
	add_child(orilla)

	# === PALMERAS LOW-POLY (estilo imagen 3) ===
	_dibujar_palmera_lowpoly(Vector2(ox + 150, 600))
	_dibujar_palmera_lowpoly(Vector2(ox + 420, 600))
	_dibujar_palmera_lowpoly(Vector2(ox + 650, 600))
	_dibujar_palmera_lowpoly(Vector2(ox + 1400, 530))
	_dibujar_palmera_lowpoly(Vector2(ox + 1800, 530))
	_dibujar_palmera_lowpoly(Vector2(ox + 2500, 600))
	_dibujar_palmera_lowpoly(Vector2(ox + 2800, 600))
	_dibujar_palmera_lowpoly(Vector2(ox + 3100, 600))

	# === SOMBRILLAS COLORIDAS (estilo imagen 3) ===
	_dibujar_sombrilla(Vector2(ox + 300, 600), Color(0.95, 0.22, 0.18, 1))
	_dibujar_sombrilla(Vector2(ox + 600, 600), Color(0.22, 0.62, 0.95, 1))
	_dibujar_sombrilla(Vector2(ox + 2000, 530), Color(0.95, 0.78, 0.10, 1))
	_dibujar_sombrilla(Vector2(ox + 2700, 600), Color(0.22, 0.88, 0.45, 1))

	# === CABAÑAS ===
	_dibujar_cabana(Vector2(ox + 500, 600))
	_dibujar_cabana(Vector2(ox + 1700, 530))

	# === KITE y conchas en la playa ===
	_dibujar_kite(Vector2(ox + 1200, 320))

	_letrero_zona(Vector2(ox + 150, 530), "SANTA MARIANITA", Color(0.65, 0.22, 0.04, 1))

func _dibujar_sol_tropical(pos: Vector2) -> void:
	var n = Node2D.new(); n.position = pos; n.z_index = -8
	# Sol
	var pts_sol = PackedVector2Array()
	for i in 20:
		var ang = i * TAU / 20
		pts_sol.append(Vector2(cos(ang) * 55, sin(ang) * 55))
	n.add_child(_poligono(pts_sol, Color(1.0, 0.92, 0.35, 0.9)))
	# Brillo interno
	var pts_bri = PackedVector2Array()
	for i in 16:
		var ang = i * TAU / 16
		pts_bri.append(Vector2(cos(ang) * 38, sin(ang) * 38))
	n.add_child(_poligono(pts_bri, Color(1.0, 0.98, 0.65, 1.0)))
	add_child(n)

func _dibujar_ola_tropical(ox: float, y: float, indice: int) -> void:
	var col_olas = [
		Color(0.50, 0.85, 0.92, 0.25),
		Color(0.40, 0.78, 0.88, 0.30),
		Color(0.30, 0.70, 0.85, 0.35),
		Color(0.22, 0.62, 0.80, 0.40),
		Color(0.15, 0.55, 0.75, 0.45),
	]
	var pts = PackedVector2Array()
	var n = 24
	for i in n + 1:
		var px = ox + i * (ZONA_ANCHO / n)
		var py = y + sin(i * 0.9 + indice * 0.8) * 10
		pts.append(Vector2(px, py))
	for i in range(n, -1, -1):
		var px = ox + i * (ZONA_ANCHO / n)
		pts.append(Vector2(px, y + 12))
	var pol = _poligono(pts, col_olas[indice], -5 + indice)
	add_child(pol)

func _dibujar_palmera_lowpoly(pos: Vector2) -> void:
	var n = Node2D.new(); n.position = pos; n.z_index = 1
	var alt = randf_range(0.85, 1.15)
	# Tronco curvo low-poly (menos vértices, más angular — estilo imagen 3)
	n.add_child(_poligono(PackedVector2Array([
		Vector2(-7, 0), Vector2(7, 0),
		Vector2(10, int(-60 * alt)),
		Vector2(15, int(-110 * alt)),
		Vector2(18, int(-155 * alt)),
		Vector2(12, int(-158 * alt)),
		Vector2(8, int(-113 * alt)),
		Vector2(3, int(-63 * alt)),
		Vector2(-1, 0)
	]), Color(0.58, 0.42, 0.22, 1)))

	# Hojas triangulares low-poly (estilo imagen 3)
	var base = Vector2(14, int(-155 * alt))
	var hojas_data = [
		[base, base + Vector2(65, -30), base + Vector2(50, -10)],  # Derecha
		[base, base + Vector2(-55, -35), base + Vector2(-42, -8)],  # Izquierda
		[base, base + Vector2(30, -65), base + Vector2(10, -58)],  # Arriba derecha
		[base, base + Vector2(-22, -60), base + Vector2(-5, -55)],  # Arriba izquierda
		[base, base + Vector2(55, -55), base + Vector2(42, -38)],  # Diagonal
	]
	var colores_hoja = [
		Color(0.18, 0.58, 0.12, 1),
		Color(0.22, 0.65, 0.15, 1),
		Color(0.15, 0.52, 0.10, 1),
		Color(0.25, 0.68, 0.18, 1),
		Color(0.20, 0.60, 0.13, 1),
	]
	for i in hojas_data.size():
		var h = hojas_data[i]
		n.add_child(_poligono(PackedVector2Array([h[0], h[1], h[2]]), colores_hoja[i]))

	# Coco (detalle)
	n.add_child(_poligono(PackedVector2Array([
		Vector2(10, int(-148 * alt)), Vector2(18, int(-148 * alt)),
		Vector2(20, int(-138 * alt)), Vector2(8, int(-138 * alt))
	]), Color(0.45, 0.28, 0.08, 1)))
	add_child(n)

func _dibujar_sombrilla(pos: Vector2, color_sombrilla: Color) -> void:
	var n = Node2D.new(); n.position = pos; n.z_index = 1
	# Palo
	n.add_child(_poligono(PackedVector2Array([
		Vector2(-2, 0), Vector2(2, 0), Vector2(1, -70), Vector2(-1, -70)
	]), Color(0.72, 0.62, 0.42, 1)))
	# Sombrilla (octágono aplanado)
	var pts = PackedVector2Array()
	for i in 8:
		var ang = i * TAU / 8 - PI / 2
		pts.append(Vector2(cos(ang) * 38, sin(ang) * 16 - 70))
	n.add_child(_poligono(pts, color_sombrilla))
	# Líneas de la sombrilla
	for i in 8:
		var ang = i * TAU / 8 - PI / 2
		var punta = _poligono(PackedVector2Array([
			Vector2(-1, -70), Vector2(1, -70),
			Vector2(cos(ang) * 38 + 1, sin(ang) * 16 - 70),
			Vector2(cos(ang) * 38 - 1, sin(ang) * 16 - 70)
		]), Color(1, 1, 1, 0.25))
		n.add_child(punta)
	# Toalla en la arena
	n.add_child(_poligono(PackedVector2Array([
		Vector2(-22, -2), Vector2(22, -2),
		Vector2(22, 2), Vector2(-22, 2)
	]), Color(color_sombrilla.r * 1.2, color_sombrilla.g * 1.2, color_sombrilla.b * 0.5, 0.8)))
	add_child(n)

# ─── ZONA 4: MANTA URBANO (mejorado) ──────────────────────────────
func _zona_manta_urbano() -> void:
	var ox = ZONAS_X[3]
	_crear_bloque_suelo_fisico(ox - 50, ox + ZONA_ANCHO + 1000, 600, Color(0.28, 0.28, 0.32, 1))

	# Líneas de pavimento
	for i in range(10):
		var lx = ox + 200 + i * 260
		var lin = _poligono(PackedVector2Array([
			Vector2(lx, 610), Vector2(lx + 120, 610),
			Vector2(lx + 120, 618), Vector2(lx, 618)
		]), Color(0.55, 0.55, 0.60, 0.5), 0)
		add_child(lin)

	# Cielo nocturno
	var cielo_n = _poligono(PackedVector2Array([
		Vector2(ox, 0), Vector2(ox + ZONA_ANCHO + 500, 0),
		Vector2(ox + ZONA_ANCHO + 500, 600), Vector2(ox, 600)
	]), Color(0.04, 0.06, 0.18, 1), -10)
	cielo_n.vertex_colors = PackedColorArray([
		Color(0.04, 0.06, 0.18, 1), Color(0.04, 0.06, 0.18, 1),
		Color(0.08, 0.10, 0.28, 1), Color(0.08, 0.10, 0.28, 1)
	])
	add_child(cielo_n)

	# Estrellas
	for si in range(25):
		var sx = ox + 80 + si * 110 + randf_range(-30, 30)
		var sy = 25 + randf_range(0, 130)
		var est = _poligono(PackedVector2Array([
			Vector2(sx, sy), Vector2(sx + 3, sy + 3),
			Vector2(sx, sy + 6), Vector2(sx - 3, sy + 3)
		]), Color(0.95, 0.90, 0.70, randf_range(0.5, 1.0)), -9)
		add_child(est)

	# Edificios
	var edificios_data = [
		{"x": ox+200, "w": 60, "h": 220, "color": Color(0.18,0.22,0.38,1)},
		{"x": ox+300, "w": 80, "h": 300, "color": Color(0.22,0.26,0.44,1)},
		{"x": ox+420, "w": 55, "h": 180, "color": Color(0.16,0.20,0.34,1)},
		{"x": ox+520, "w": 100, "h": 340, "color": Color(0.24,0.28,0.48,1)},
		{"x": ox+680, "w": 70, "h": 250, "color": Color(0.20,0.24,0.40,1)},
		{"x": ox+800, "w": 55, "h": 160, "color": Color(0.18,0.22,0.36,1)},
		{"x": ox+1500, "w": 90, "h": 280, "color": Color(0.22,0.26,0.44,1)},
		{"x": ox+1640, "w": 65, "h": 200, "color": Color(0.18,0.22,0.38,1)},
		{"x": ox+1760, "w": 110, "h": 360, "color": Color(0.26,0.30,0.50,1)},
	]
	for ed in edificios_data:
		_dibujar_edificio(ed.x, ed.w, ed.h, ed.color)

	_dibujar_megaparque(Vector2(ox + 1050, 600))
	_dibujar_haz_de_luz(Vector2(ox + 2200, 0))
	_dibujar_monumento_luz(Vector2(ox + 2200, 600))
	_letrero_zona(Vector2(ox + 150, 530), "MANTA URBANO", Color(0.55, 0.72, 1.0, 1))

# ══════════════════════════════════════════════════════════════════
#  ELEMENTOS VISUALES COMPARTIDOS
# ══════════════════════════════════════════════════════════════════
func _dibujar_faro(pos: Vector2) -> void:
	var n = Node2D.new(); n.position = pos; n.z_index = 0
	n.add_child(_poligono(PackedVector2Array([
		Vector2(-55,0),Vector2(55,0),Vector2(42,-28),Vector2(-42,-28)]),
		Color(0.42, 0.36, 0.28, 1)))
	n.add_child(_poligono(PackedVector2Array([
		Vector2(-25,0),Vector2(25,0),Vector2(19,-190),Vector2(-19,-190)]),
		Color(0.95, 0.95, 0.92, 1)))
	for i in 3:
		n.add_child(_poligono(PackedVector2Array([
			Vector2(-25,-40 - i*55), Vector2(25,-40 - i*55),
			Vector2(23,-62 - i*55), Vector2(-23,-62 - i*55)]),
			Color(0.85, 0.12, 0.12, 1)))
	n.add_child(_poligono(PackedVector2Array([
		Vector2(-32,-188),Vector2(32,-188),Vector2(28,-200),Vector2(-28,-200)]),
		Color(0.58, 0.55, 0.50, 1)))
	n.add_child(_poligono(PackedVector2Array([
		Vector2(-16,-200),Vector2(16,-200),Vector2(8,-228),Vector2(0,-235),Vector2(-8,-228)]),
		Color(0.12, 0.12, 0.14, 1)))
	n.add_child(_poligono(PackedVector2Array([
		Vector2(-7,-228),Vector2(7,-228),Vector2(5,-238),Vector2(-5,-238)]),
		Color(1.0, 0.95, 0.45, 1)))
	n.add_child(_poligono(PackedVector2Array([
		Vector2(0,-232),Vector2(180,-165),Vector2(175,-150),Vector2(0,-225)]),
		Color(1.0, 0.95, 0.45, 0.15)))
	add_child(n)

func _dibujar_arbol_selva(pos: Vector2) -> void:
	var n = Node2D.new(); n.position = pos; n.z_index = -1
	n.add_child(_poligono(PackedVector2Array([
		Vector2(-18,0),Vector2(18,0),Vector2(14,-200),Vector2(-14,-200)]),
		Color(0.22, 0.14, 0.06, 1)))
	n.add_child(_poligono(PackedVector2Array([
		Vector2(-55,0),Vector2(-18,0),Vector2(-18,-40),Vector2(-40,-20)]),
		Color(0.20, 0.12, 0.05, 1)))
	n.add_child(_poligono(PackedVector2Array([
		Vector2(18,0),Vector2(55,0),Vector2(40,-20),Vector2(18,-40)]),
		Color(0.20, 0.12, 0.05, 1)))
	n.add_child(_poligono(PackedVector2Array([
		Vector2(-100,-180),Vector2(100,-180),Vector2(80,-260),Vector2(0,-300),Vector2(-80,-260)]),
		Color(0.08, 0.28, 0.06, 1)))
	n.add_child(_poligono(PackedVector2Array([
		Vector2(-78,-200),Vector2(78,-200),Vector2(55,-275),Vector2(0,-315),Vector2(-55,-275)]),
		Color(0.12, 0.36, 0.08, 1)))
	n.add_child(_poligono(PackedVector2Array([
		Vector2(-52,-220),Vector2(52,-220),Vector2(32,-290),Vector2(0,-330),Vector2(-32,-290)]),
		Color(0.16, 0.44, 0.10, 1)))
	add_child(n)

func _dibujar_liana(pos: Vector2) -> void:
	var n = Node2D.new(); n.position = pos; n.z_index = 0
	n.add_child(_poligono(PackedVector2Array([
		Vector2(-3,0),Vector2(3,0),Vector2(5,80),Vector2(10,160),
		Vector2(8,240),Vector2(2,320),Vector2(-2,320),
		Vector2(-8,240),Vector2(-10,160),Vector2(-5,80)]),
		Color(0.18, 0.45, 0.10, 0.85)))
	n.add_child(_poligono(PackedVector2Array([
		Vector2(5,100),Vector2(28,90),Vector2(24,102),Vector2(4,115)]),
		Color(0.20, 0.50, 0.12, 0.9)))
	n.add_child(_poligono(PackedVector2Array([
		Vector2(-8,200),Vector2(-32,188),Vector2(-28,202),Vector2(-6,215)]),
		Color(0.22, 0.52, 0.14, 0.9)))
	add_child(n)

func _dibujar_mono(pos: Vector2) -> void:
	var n = Node2D.new(); n.position = pos; n.z_index = 1
	n.add_child(_poligono(PackedVector2Array([
		Vector2(-14,0),Vector2(14,0),Vector2(12,-30),Vector2(-12,-30)]),
		Color(0.15, 0.08, 0.04, 1)))
	n.add_child(_poligono(PackedVector2Array([
		Vector2(-12,-30),Vector2(12,-30),Vector2(10,-50),Vector2(0,-56),Vector2(-10,-50)]),
		Color(0.18, 0.10, 0.05, 1)))
	n.add_child(_poligono(PackedVector2Array([
		Vector2(-8,-35),Vector2(8,-35),Vector2(8,-48),Vector2(-8,-48)]),
		Color(0.72, 0.60, 0.45, 1)))
	for lado in [-6, 2]:
		n.add_child(_poligono(PackedVector2Array([
			Vector2(lado,-44),Vector2(lado+4,-44),Vector2(lado+4,-40),Vector2(lado,-40)]),
			Color(0.04, 0.02, 0.01, 1)))
	n.add_child(_poligono(PackedVector2Array([
		Vector2(-14,-25),Vector2(-42,-10),Vector2(-44,-4),Vector2(-14,-18)]),
		Color(0.15, 0.08, 0.04, 1)))
	n.add_child(_poligono(PackedVector2Array([
		Vector2(14,-25),Vector2(42,-10),Vector2(44,-4),Vector2(14,-18)]),
		Color(0.15, 0.08, 0.04, 1)))
	n.add_child(_poligono(PackedVector2Array([
		Vector2(14,-15),Vector2(18,-15),Vector2(50,20),Vector2(55,55),Vector2(45,55),Vector2(42,22)]),
		Color(0.15, 0.08, 0.04, 1)))
	add_child(n)

func _dibujar_palmera(pos: Vector2) -> void:
	var n = Node2D.new(); n.position = pos; n.z_index = 0
	n.add_child(_poligono(PackedVector2Array([
		Vector2(-6,0),Vector2(6,0),Vector2(16,-80),Vector2(22,-140),
		Vector2(28,-180),Vector2(22,-182),Vector2(14,-142),Vector2(8,-80),Vector2(0,-2)]),
		Color(0.52, 0.38, 0.18, 1)))
	var hoja_positions = [
		PackedVector2Array([Vector2(28,-178),Vector2(80,-158),Vector2(72,-150),Vector2(26,-168)]),
		PackedVector2Array([Vector2(28,-178),Vector2(28,-120),Vector2(18,-118),Vector2(20,-175)]),
		PackedVector2Array([Vector2(28,-178),Vector2(-20,-155),Vector2(-16,-146),Vector2(24,-170)]),
		PackedVector2Array([Vector2(28,-178),Vector2(70,-198),Vector2(64,-190),Vector2(26,-172)]),
	]
	for hp in hoja_positions:
		n.add_child(_poligono(hp, Color(0.22, 0.55, 0.12, 1)))
	add_child(n)

func _dibujar_ola(ox: float, y: float) -> void:
	var pts = PackedVector2Array()
	var n = 20
	for i in n+1:
		var px = ox + i * (ZONA_ANCHO / n)
		var py = y + sin(i * 0.8) * 12
		pts.append(Vector2(px, py))
	for i in range(n, -1, -1):
		var px = ox + i * (ZONA_ANCHO / n)
		pts.append(Vector2(px, y + 10))
	var pol = _poligono(pts, Color(0.55, 0.72, 0.95, 0.35), -1)
	add_child(pol)

func _dibujar_kite(pos: Vector2) -> void:
	var n = Node2D.new(); n.position = pos; n.z_index = 0
	n.add_child(_poligono(PackedVector2Array([
		Vector2(0,-40),Vector2(28,-8),Vector2(0,28),Vector2(-28,-8)]),
		Color(0.92, 0.22, 0.08, 1)))
	n.add_child(_poligono(PackedVector2Array([
		Vector2(-2,28),Vector2(2,28),Vector2(18,200),Vector2(-18,200)]),
		Color(0.62, 0.62, 0.72, 0.7)))
	add_child(n)

func _dibujar_cabana(pos: Vector2) -> void:
	var n = Node2D.new(); n.position = pos; n.z_index = 0
	n.add_child(_poligono(PackedVector2Array([
		Vector2(-45,0),Vector2(45,0),Vector2(42,-55),Vector2(-42,-55)]),
		Color(0.78, 0.60, 0.38, 1)))
	n.add_child(_poligono(PackedVector2Array([
		Vector2(-55,-55),Vector2(55,-55),Vector2(40,-90),Vector2(0,-105),Vector2(-40,-90)]),
		Color(0.72, 0.58, 0.25, 1)))
	n.add_child(_poligono(PackedVector2Array([
		Vector2(-55,-55),Vector2(55,-55),Vector2(50,-68),Vector2(-50,-68)]),
		Color(0.62, 0.48, 0.18, 1)))
	n.add_child(_poligono(PackedVector2Array([
		Vector2(-10,0),Vector2(10,0),Vector2(10,-30),Vector2(-10,-30)]),
		Color(0.42, 0.26, 0.08, 1)))
	add_child(n)

func _dibujar_edificio(x: float, w: float, h: float, col: Color) -> void:
	var n = Node2D.new(); n.position = Vector2(x, 600); n.z_index = -1
	n.add_child(_poligono(PackedVector2Array([
		Vector2(0,0),Vector2(w,0),Vector2(w,-h),Vector2(0,-h)]), col))
	var filas = int(h / 35)
	for fi in filas:
		for ci in [6, 14, 22]:
			if ci + 7 < w:
				n.add_child(_poligono(PackedVector2Array([
					Vector2(ci, -20 - fi*35), Vector2(ci+7, -20 - fi*35),
					Vector2(ci+7, -30 - fi*35), Vector2(ci, -30 - fi*35)]),
					Color(0.95, 0.88, 0.55, 0.7) if randf() > 0.3 else Color(0.12, 0.14, 0.22, 1)))
	add_child(n)

func _dibujar_megaparque(pos: Vector2) -> void:
	var n = Node2D.new(); n.position = pos; n.z_index = 0
	var pts_ext = PackedVector2Array()
	var pts_int = PackedVector2Array()
	for i in 24:
		var ang = i * TAU / 24
		pts_ext.append(Vector2(cos(ang)*95, sin(ang)*30))
		pts_int.append(Vector2(cos(ang)*70, sin(ang)*22))
	n.add_child(_poligono(pts_ext, Color(0.28, 0.38, 0.22, 1)))
	n.add_child(_poligono(pts_int, Color(0.22, 0.30, 0.18, 1)))
	for i in 6:
		var ang = i * TAU / 6
		n.add_child(_poligono(PackedVector2Array([
			Vector2(cos(ang)*5, sin(ang)*2),
			Vector2(cos(ang+0.15)*5, sin(ang+0.15)*2),
			Vector2(cos(ang+0.08)*90, sin(ang+0.08)*28),
			Vector2(cos(ang-0.08)*90, sin(ang-0.08)*28)]),
			Color(0.58, 0.52, 0.40, 0.7)))
	var pts_c = PackedVector2Array()
	for i in 12:
		var ang = i * TAU / 12
		pts_c.append(Vector2(cos(ang)*18, sin(ang)*8))
	n.add_child(_poligono(pts_c, Color(0.72, 0.58, 0.25, 1)))
	var lbl = Label.new()
	lbl.text = "MEGAPARQUE"
	lbl.position = Vector2(-50, -48)
	lbl.add_theme_font_size_override("font_size", 12)
	lbl.add_theme_color_override("font_color", Color(0.95, 0.80, 0.10, 0.9))
	n.add_child(lbl)
	add_child(n)

func _dibujar_haz_de_luz(pos: Vector2) -> void:
	var n = Node2D.new(); n.position = pos; n.z_index = 5
	n.add_child(_poligono(PackedVector2Array([
		Vector2(-80,0),Vector2(80,0),Vector2(40,720),Vector2(-40,720)]),
		Color(0.65, 0.85, 1.0, 0.12)))
	n.add_child(_poligono(PackedVector2Array([
		Vector2(-30,0),Vector2(30,0),Vector2(15,720),Vector2(-15,720)]),
		Color(0.75, 0.92, 1.0, 0.18)))
	n.add_child(_poligono(PackedVector2Array([
		Vector2(-8,0),Vector2(8,0),Vector2(5,720),Vector2(-5,720)]),
		Color(0.90, 0.97, 1.0, 0.30)))
	var zona = Area2D.new()
	var col = CollisionShape2D.new()
	var forma = RectangleShape2D.new()
	forma.size = Vector2(160, 720)
	col.shape = forma
	col.position = Vector2(0, 360)
	zona.add_child(col)
	zona.body_entered.connect(_on_meta_alcanzada)
	n.add_child(zona)
	add_child(n)

func _dibujar_monumento_luz(pos: Vector2) -> void:
	var n = Node2D.new(); n.position = pos; n.z_index = 1
	n.add_child(_poligono(PackedVector2Array([
		Vector2(-80,0),Vector2(80,0),Vector2(65,-40),Vector2(-65,-40)]),
		Color(0.68, 0.68, 0.72, 1)))
	n.add_child(_poligono(PackedVector2Array([
		Vector2(-55,-40),Vector2(55,-40),Vector2(40,-80),Vector2(-40,-80)]),
		Color(0.72, 0.72, 0.78, 1)))
	n.add_child(_poligono(PackedVector2Array([
		Vector2(-22,-80),Vector2(22,-80),Vector2(16,-200),Vector2(-16,-200)]),
		Color(0.78, 0.78, 0.84, 1)))
	n.add_child(_poligono(PackedVector2Array([
		Vector2(-16,-200),Vector2(16,-200),Vector2(8,-280),Vector2(0,-300),Vector2(-8,-280)]),
		Color(0.85, 0.85, 0.92, 1)))
	n.add_child(_poligono(PackedVector2Array([
		Vector2(-6,-295),Vector2(6,-295),Vector2(2,-320),Vector2(0,-328),Vector2(-2,-320)]),
		Color(0.95, 0.78, 0.10, 1)))
	add_child(n)

func _letrero_zona(pos: Vector2, texto: String, col: Color) -> void:
	var n = Node2D.new(); n.position = pos; n.z_index = 2
	n.add_child(_poligono(PackedVector2Array([
		Vector2(-5,5),Vector2(130,5),Vector2(130,-28),Vector2(-5,-28)]),
		Color(0,0,0,0.55)))
	var lbl = Label.new()
	lbl.text = texto
	lbl.position = Vector2(0, -26)
	lbl.add_theme_font_size_override("font_size", 18)
	lbl.add_theme_color_override("font_color", col)
	n.add_child(lbl)
	add_child(n)

func _crear_bloque_suelo_fisico(x_inicio: float, x_fin: float, altura_y: float, color_bloque: Color) -> void:
	var cuerpo   = StaticBody2D.new()
	var colision = CollisionShape2D.new()
	var forma    = RectangleShape2D.new()
	var ancho    = x_fin - x_inicio
	var alto     = 200.0
	forma.size = Vector2(ancho, alto)
	colision.shape = forma
	cuerpo.position = Vector2(x_inicio + ancho / 2.0, altura_y + alto / 2.0)
	cuerpo.add_child(colision)
	var vis = _poligono(PackedVector2Array([
		Vector2(x_inicio, altura_y), Vector2(x_fin, altura_y),
		Vector2(x_fin, altura_y + alto), Vector2(x_inicio, altura_y + alto)
	]), color_bloque, -2)
	add_child(cuerpo)
	add_child(vis)

# ══════════════════════════════════════════════════════════════════
#  SPAWN
# ══════════════════════════════════════════════════════════════════
func _spawn_obstaculo() -> void:
	if escena_obstaculo == null or en_transicion:
		return
	var obs = escena_obstaculo.instantiate()
	var zona = GameManager.zona_actual
	match zona:
		1:  # Pacoche: obstáculo aéreo cae desde arriba
			obs.position = Vector2(player.position.x + 900, -80)
		_:
			obs.position = Vector2(player.position.x + 900, 600)
	add_child(obs)

func _spawn_gema() -> void:
	if escena_concha == null or en_transicion:
		return
	if GameManager.gemas_zona >= 5:
		return
	var gema = escena_concha.instantiate()
	# Adaptar altura de gema a la zona actual
	var altura_gema := 460.0
	match GameManager.zona_actual:
		1: altura_gema = randf_range(380, 520)  # Pacoche: gemas a distintas alturas (plataformas)
		2: altura_gema = randf_range(420, 520)  # Santa Mar: nivel de duna
		_: altura_gema = randf_range(460, 560)
	gema.position = Vector2(
		player.position.x + 500 + randf_range(0, 300),
		altura_gema)
	add_child(gema)

# ══════════════════════════════════════════════════════════════════
#  SEÑALES
# ══════════════════════════════════════════════════════════════════
func _on_score_changed(v: int) -> void:
	# Mostrar multiplicador de combo en el score
	var mult = GameManager.COMBO_MULTIPLICADORES[GameManager.combo_nivel]
	if mult > 1:
		score_lbl.text = "Puntos: %d  [x%d]" % [v, mult]
	else:
		score_lbl.text = "Puntos: %d" % v

func _on_vidas_changed(v: int) -> void:
	_actualizar_corazones(v)

func _on_gema_recolectada(total_zona: int) -> void:
	gemas_actuales = total_zona
	gemas_lbl.text = "Gemas: %d/5" % total_zona
	_mostrar_mensaje("¡Gema %d/5!" % total_zona, 0.8)
	if total_zona >= 5:
		if GameManager.zona_actual == 3 or GameManager.zona_actual >= 4:
			await get_tree().create_timer(0.5).timeout
			_ir_a_fase_dos_mar()

func _on_zona_completada(zona_idx: int) -> void:
	if zona_idx >= 3 or GameManager.zona_actual >= 4:
		_ir_a_fase_dos_mar()
		return
	en_transicion = true
	gemas_actuales = 0
	if zona_idx + 1 < ZONAS_INFO.size():
		_mostrar_mensaje("¡Zona Superada!\nViajando a: " + ZONAS_INFO[zona_idx + 1].nombre, 3.0)
	else:
		_mostrar_mensaje("¡Zona Superada!\nAvanza a la siguiente etapa", 3.0)
	await get_tree().create_timer(3.0).timeout
	en_transicion = false

func _on_meta_alcanzada(body) -> void:
	if meta_alcanzada:
		return
	if not (body.name == "Player" or body.is_in_group("player")):
		return
	meta_alcanzada = true
	_ir_a_fase_dos_mar()

# ══════════════════════════════════════════════════════════════════
#  HUD
# ══════════════════════════════════════════════════════════════════
func _actualizar_corazones(vidas_activas: int) -> void:
	for i in corazones.size():
		var c = corazones[i]
		if i < vidas_activas:
			c.color = Color(0.92, 0.14, 0.14, 1)
		else:
			c.color = Color(0.28, 0.14, 0.14, 0.45)
			if i == vidas_activas:
				var tw = create_tween()
				tw.tween_property(c, "scale", Vector2(1.5, 1.5), 0.08)
				tw.tween_property(c, "scale", Vector2(1.0, 1.0), 0.18)

func _mostrar_mensaje(texto: String, duracion: float) -> void:
	msg_panel.visible = true
	msg_lbl.text = texto
	await get_tree().create_timer(duracion).timeout
	msg_panel.visible = false

# ══════════════════════════════════════════════════════════════════
#  UTIL
# ══════════════════════════════════════════════════════════════════
func _poligono(pts: PackedVector2Array, col: Color, zi: int = 0) -> Polygon2D:
	var p = Polygon2D.new()
	p.polygon = pts
	p.color   = col
	p.z_index = zi
	return p

func _ir_a_fase_dos_mar() -> void:
	set_process(false)
	set_physics_process(false)
	if player and player.has_method("detener_para_dialogo"):
		player.detener_para_dialogo()
	_mostrar_mensaje("¡Has llegado al puerto de Manta!\nPreparando las redes para la pesca...", 1.5)
	await get_tree().create_timer(1.5).timeout
	var ruta = "res://scenes/fasedos.tscn"
	if ResourceLoader.exists(ruta):
		get_tree().change_scene_to_file(ruta)
	else:
		get_tree().change_scene_to_file("res://scenes/fase_dos.tscn")

func _draw() -> void:
	if not is_instance_valid(player) or not is_instance_valid(camera):
		return
	var centro_camara_x = camera.get_screen_center_position().x

	# Paisaje infinito San Lorenzo (montañas lejanas en parallax)
	if GameManager.zona_actual == 0:
		var base_x = centro_camara_x - 640 + (int(centro_camara_x * 0.12) % 1280)
		for offset in [-1280, 0, 1280]:
			var rx = base_x + offset
			var picos = PackedVector2Array([
				Vector2(rx - 200, 600),
				Vector2(rx + 100, 450), Vector2(rx + 280, 490),
				Vector2(rx + 500, 400), Vector2(rx + 700, 440),
				Vector2(rx + 900, 380), Vector2(rx + 1100, 430),
				Vector2(rx + 1300, 360), Vector2(rx + 1480, 600)
			])
			draw_polygon(picos, [Color(0.32, 0.55, 0.28, 0.5)])

	# Paisaje infinito Santa Marianita
	elif GameManager.zona_actual == 2:
		# Reflejos de luz en el agua
		draw_rect(Rect2(centro_camara_x - 640, 360, 1280, 130), Color(0.20, 0.65, 0.82, 0.22))
		# Nubes en movimiento
		var base_nubes_x = (int(centro_camara_x * 0.06) % 1600)
		for offset in [-1600, 0, 1600]:
			var nx = (centro_camara_x - 640) - base_nubes_x + offset + 400
			draw_circle(Vector2(nx, 130), 48, Color(0.96, 0.97, 0.99, 0.80))
			draw_circle(Vector2(nx + 55, 105), 65, Color(0.97, 0.98, 1.0, 0.88))
			draw_circle(Vector2(nx + 115, 132), 44, Color(0.96, 0.97, 0.99, 0.80))
