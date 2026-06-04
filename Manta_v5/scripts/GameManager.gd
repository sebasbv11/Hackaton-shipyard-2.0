extends Node

# ══════════════════════════════════════════════════════════════════
#  GameManager.gd — v6 con Sistema de COMBO x2/x3/x4
# ══════════════════════════════════════════════════════════════════

var score: int       = 0
var vidas: int       = 5
var gemas_zona: int  = 0
var zona_actual: int = 0
var current_phase: int = 1

# 🌟 NUEVO: Sistema de Combo
var combo_contador: int = 0   # Gemas seguidas sin recibir daño
var combo_nivel: int    = 0   # 0=normal, 1=x2, 2=x3, 3=x4
var combo_activo: bool  = false

signal score_changed(new_score)
signal vidas_changed(new_vidas)
signal gema_recolectada(total_zona)
signal zona_completada(zona_idx)
signal combo_changed(nivel, multiplicador)  # 🌟 NUEVA SEÑAL

# Multiplicadores según nivel de combo
const COMBO_MULTIPLICADORES := [1, 2, 3, 4]
const COMBO_UMBRALES := [0, 3, 6, 10]  # Gemas necesarias para subir de nivel

func add_score(amount: int) -> void:
	var mult = COMBO_MULTIPLICADORES[combo_nivel]
	score = max(0, score + amount * mult)
	score_changed.emit(score)

func recolectar_gema() -> void:
	gemas_zona += 1
	combo_contador += 1
	_actualizar_combo()
	
	var mult = COMBO_MULTIPLICADORES[combo_nivel]
	score += 10 * mult
	score_changed.emit(score)
	gema_recolectada.emit(gemas_zona)
	if gemas_zona >= 5:
		gemas_zona = 0
		zona_completada.emit(zona_actual)
		zona_actual += 1

func _actualizar_combo() -> void:
	var nuevo_nivel = 0
	for i in COMBO_UMBRALES.size():
		if combo_contador >= COMBO_UMBRALES[i]:
			nuevo_nivel = i
	if nuevo_nivel != combo_nivel:
		combo_nivel = nuevo_nivel
		combo_activo = combo_nivel > 0
		combo_changed.emit(combo_nivel, COMBO_MULTIPLICADORES[combo_nivel])

func romper_combo() -> void:
	# Se llama cuando el jugador recibe daño
	if combo_nivel > 0:
		combo_nivel = 0
		combo_contador = 0
		combo_activo = false
		combo_changed.emit(0, 1)

func perder_vida() -> void:
	vidas = max(0, vidas - 1)
	vidas_changed.emit(vidas)
	romper_combo()  # 🌟 Recibir daño rompe el combo

func reset() -> void:
	score       = 0
	vidas       = 5
	gemas_zona  = 0
	zona_actual = 0
	current_phase = 1
	combo_contador = 0
	combo_nivel    = 0
	combo_activo   = false
