# MobileOptimizations.gd
# Script para optimizaciones adicionales de mobile
extends Node

static var safe_area: Rect2i:
	get:
		return DisplayServer.screen_get_usable_rect()

static var viewport_size: Vector2:
	get:
		return get_viewport().get_visible_rect().size

static var is_mobile: bool:
	get:
		return OS.get_name() in ["Android", "iOS"]

static var screen_dpi: float:
	get:
		return DisplayServer.screen_get_dpi()

static var orientation: String:
	get:
		var size = viewport_size
		return "portrait" if size.y > size.x else "landscape"

# Detectar si hay notch/cutout
static func has_notch() -> bool:
	if not is_mobile:
		return false
	var sa = safe_area
	return sa.position.y > 0 or sa.position.x > 0

# Obtener área segura (evita notch)
static func get_safe_margin_top() -> int:
	if not is_mobile:
		return 0
	return safe_area.position.y

static func get_safe_margin_left() -> int:
	if not is_mobile:
		return 0
	return safe_area.position.x

# Escalar UI para diferentes DPIs
static func scale_for_dpi(base_size: float) -> float:
	if not is_mobile:
		return base_size
	var dpi = screen_dpi
	var scale_factor = dpi / 160.0  # Referencia: Android 160 DPI
	return base_size * scale_factor

# Habilitar fullscreen inmersivo (sin barras en Android)
static func enable_immersive_mode() -> void:
	if is_mobile:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)

# Mantener pantalla activa
static func keep_screen_on(enabled: bool = true) -> void:
	if OS.get_name() == "Android":
		if enabled:
			OS.set_low_processor_usage_mode(false)
