extends StaticBody2D

# ══════════════════════════════════════════════════════════════════
#  Obstacle.gd — v6: Comportamiento diferente por zona
#  Zona 0 (San Lorenzo): obstáculo normal en suelo
#  Zona 1 (Pacoche):     ramas que caen desde arriba (aéreo)
#  Zona 2 (Santa Mar.):  cangrejo/animal que se mueve lateral
#  Zona 3 (Manta Urb.):  bache + carro lento
# ══════════════════════════════════════════════════════════════════

const MOVE_SPEED: float = 210.0

var tipo_zona: int = 0
var vel_x: float   = -210.0
var vel_y: float   = 0.0
var es_aereo: bool = false
var destruido: bool = false

# Para la rama que cae
var cayendo: bool     = false
var gravedad_propia: float = 0.0

func _ready() -> void:
	add_to_group("obstaculo")
	tipo_zona = GameManager.zona_actual
	_configurar_por_zona()

func _configurar_por_zona() -> void:
	match tipo_zona:
		0: # San Lorenzo — tronco flotante normal
			vel_x = -MOVE_SPEED
			_dibujar_tronco()

		1: # Pacoche — RAMA QUE CAE desde arriba
			es_aereo = true
			vel_x = -MOVE_SPEED * 0.3  # Se mueve poco hacia la izquierda
			vel_y = 0.0
			cayendo = false
			gravedad_propia = 680.0
			# La rama empieza arriba, fuera de pantalla
			position.y = -80.0
			_dibujar_rama()
			# Espera un momento y luego empieza a caer
			var t = get_tree().create_timer(randf_range(0.2, 0.8))
			t.timeout.connect(func(): cayendo = true)

		2: # Santa Marianita — CANGREJO que se mueve de lado
			vel_x = -MOVE_SPEED * 0.6
			_dibujar_cangrejo()
			# Animación de movimiento lateral (zigzag)
			var tw = create_tween().set_loops()
			tw.tween_property(self, "position:y", position.y - 18, 0.4)
			tw.tween_property(self, "position:y", position.y, 0.4)

		3: # Manta Urbano — COCHE lento que pita
			vel_x = -MOVE_SPEED * 0.45
			_dibujar_coche()

func _process(delta: float) -> void:
	if destruido:
		return

	match tipo_zona:
		1: # Rama cayendo
			if cayendo:
				vel_y += gravedad_propia * delta
				position.y += vel_y * delta
			position.x += vel_x * delta
			# Si ya tocó el suelo (Y > 600) se queda quieta como obstáculo normal
			if position.y >= 580:
				position.y = 580
				vel_y = 0.0
				cayendo = false
				vel_x = -MOVE_SPEED  # Ahora avanza como obstáculo normal
		_:
			position.x += vel_x * delta

	# Destruir si sale de pantalla
	if position.x < -500.0:
		queue_free()

# ─── DIBUJOS POR ZONA ────────────────────────────────────────────

func _dibujar_tronco() -> void:
	# Tronco con clavos — obstáculo clásico
	var cuerpo = Polygon2D.new()
	cuerpo.polygon = PackedVector2Array([
		Vector2(-26, -22), Vector2(26, -22),
		Vector2(30, 0),    Vector2(-30, 0)
	])
	cuerpo.color = Color(0.38, 0.24, 0.10, 1)
	add_child(cuerpo)
	# Veta de madera
	var veta = Polygon2D.new()
	veta.polygon = PackedVector2Array([
		Vector2(-24, -14), Vector2(24, -14),
		Vector2(24, -10), Vector2(-24, -10)
	])
	veta.color = Color(0.30, 0.18, 0.07, 0.6)
	add_child(veta)
	# Clavos/pinchos encima
	for i in 3:
		var clavo = Polygon2D.new()
		var cx = -16 + i * 16
		clavo.polygon = PackedVector2Array([
			Vector2(cx - 4, -22), Vector2(cx + 4, -22),
			Vector2(cx, -36)
		])
		clavo.color = Color(0.55, 0.45, 0.15, 1)
		add_child(clavo)

	# Colisión
	var col = CollisionShape2D.new()
	var forma = RectangleShape2D.new()
	forma.size = Vector2(56, 36)
	col.shape = forma
	col.position = Vector2(0, -11)
	add_child(col)

func _dibujar_rama() -> void:
	# Rama horizontal que cae desde los árboles de Pacoche
	var rama = Polygon2D.new()
	rama.polygon = PackedVector2Array([
		Vector2(-50, -5), Vector2(50, -5),
		Vector2(48, 5),   Vector2(-48, 5)
	])
	rama.color = Color(0.22, 0.14, 0.06, 1)
	add_child(rama)
	# Hojas
	for i in 4:
		var hoja = Polygon2D.new()
		var hx = -40 + i * 26
		hoja.polygon = PackedVector2Array([
			Vector2(hx - 12, -5), Vector2(hx + 12, -5),
			Vector2(hx + 8, -22), Vector2(hx, -28), Vector2(hx - 8, -22)
		])
		hoja.color = Color(0.10, 0.35, 0.08, 0.9)
		add_child(hoja)
	# Colisión
	var col = CollisionShape2D.new()
	var forma = RectangleShape2D.new()
	forma.size = Vector2(100, 30)
	col.shape = forma
	col.position = Vector2(0, -2)
	add_child(col)

func _dibujar_cangrejo() -> void:
	# Cangrejo colorido para Santa Marianita
	# Cuerpo
	var cuerpo = Polygon2D.new()
	cuerpo.polygon = PackedVector2Array([
		Vector2(-20, -8), Vector2(20, -8),
		Vector2(22, 0),   Vector2(-22, 0)
	])
	cuerpo.color = Color(0.88, 0.25, 0.08, 1)
	add_child(cuerpo)
	# Caparazón
	var carap = Polygon2D.new()
	carap.polygon = PackedVector2Array([
		Vector2(-16, -8), Vector2(16, -8),
		Vector2(14, -22), Vector2(0, -26), Vector2(-14, -22)
	])
	carap.color = Color(0.95, 0.35, 0.10, 1)
	add_child(carap)
	# Ojos
	for lado in [-8, 8]:
		var ojo = Polygon2D.new()
		ojo.polygon = PackedVector2Array([
			Vector2(lado - 3, -26), Vector2(lado + 3, -26),
			Vector2(lado + 3, -20), Vector2(lado - 3, -20)
		])
		ojo.color = Color(0.05, 0.05, 0.05, 1)
		add_child(ojo)
	# Pinzas
	for lado in [-1, 1]:
		var pinza = Polygon2D.new()
		pinza.polygon = PackedVector2Array([
			Vector2(lado * 22, -6), Vector2(lado * 22, -2),
			Vector2(lado * 36, -8), Vector2(lado * 38, -14),
			Vector2(lado * 30, -16)
		])
		pinza.color = Color(0.78, 0.18, 0.05, 1)
		add_child(pinza)
	# Patas
	for i in 3:
		for lado in [-1, 1]:
			var pata = Polygon2D.new()
			var px = lado * (10 + i * 6)
			pata.polygon = PackedVector2Array([
				Vector2(px, 0), Vector2(px + lado * 2, 0),
				Vector2(px + lado * 8, 12), Vector2(px + lado * 6, 12)
			])
			pata.color = Color(0.82, 0.22, 0.07, 1)
			add_child(pata)
	# Colisión
	var col = CollisionShape2D.new()
	var forma = RectangleShape2D.new()
	forma.size = Vector2(44, 28)
	col.shape = forma
	col.position = Vector2(0, -10)
	add_child(col)

func _dibujar_coche() -> void:
	# Coche/taxi urbano para Manta Urbano
	# Carrocería
	var car = Polygon2D.new()
	car.polygon = PackedVector2Array([
		Vector2(-38, -10), Vector2(38, -10),
		Vector2(40, 0),    Vector2(-40, 0)
	])
	car.color = Color(0.90, 0.75, 0.05, 1)  # Amarillo taxi
	add_child(car)
	# Techo
	var techo = Polygon2D.new()
	techo.polygon = PackedVector2Array([
		Vector2(-25, -10), Vector2(25, -10),
		Vector2(20, -28),  Vector2(-20, -28)
	])
	techo.color = Color(0.85, 0.68, 0.04, 1)
	add_child(techo)
	# Ventanas
	var vent = Polygon2D.new()
	vent.polygon = PackedVector2Array([
		Vector2(-18, -12), Vector2(18, -12),
		Vector2(15, -26),  Vector2(-15, -26)
	])
	vent.color = Color(0.55, 0.75, 0.95, 0.85)
	add_child(vent)
	# Ruedas
	for rx in [-24, 24]:
		var rueda = Polygon2D.new()
		var pts = PackedVector2Array()
		for i in 10:
			var ang = i * TAU / 10
			pts.append(Vector2(rx + cos(ang) * 10, sin(ang) * 10))
		rueda.polygon = pts
		rueda.color = Color(0.12, 0.12, 0.12, 1)
		add_child(rueda)
	# Faros
	for fx in [-36, 36]:
		var faro = Polygon2D.new()
		faro.polygon = PackedVector2Array([
			Vector2(fx - 3, -6), Vector2(fx + 3, -6),
			Vector2(fx + 3, -2), Vector2(fx - 3, -2)
		])
		faro.color = Color(1.0, 0.95, 0.5, 1)
		add_child(faro)
	# Colisión
	var col = CollisionShape2D.new()
	var forma = RectangleShape2D.new()
	forma.size = Vector2(76, 28)
	col.shape = forma
	col.position = Vector2(0, -5)
	add_child(col)
