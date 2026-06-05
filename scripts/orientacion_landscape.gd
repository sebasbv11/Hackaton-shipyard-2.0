extends Node

## Autoload: fuerza experiencia horizontal y muestra overlay en móvil vertical.

const VIEWPORT_W := 1280
const VIEWPORT_H := 720

var _overlay: CanvasLayer
var _panel: Control
var _last_blocked := false


func _ready() -> void:
	_build_overlay()
	get_tree().root.size_changed.connect(_refresh)
	DisplayServer.window_set_size(DisplayServer.window_get_size())
	call_deferred("_refresh")


func _process(_delta: float) -> void:
	_refresh()


func get_game_size() -> Vector2:
	return Vector2(VIEWPORT_W, VIEWPORT_H)


func is_portrait_blocked() -> bool:
	return _last_blocked


func _refresh() -> void:
	if _overlay == null:
		return
	var blocked := _should_block_portrait()
	_last_blocked = blocked
	_overlay.visible = blocked


func _should_block_portrait() -> bool:
	if not _is_mobile_like():
		return false
	var size := get_viewport().get_visible_rect().size
	if size.x < 8.0 or size.y < 8.0:
		return false
	return size.y > size.x


func _is_mobile_like() -> bool:
	return OS.has_feature("mobile") or OS.has_feature("android") or OS.has_feature("ios")


func _build_overlay() -> void:
	_overlay = CanvasLayer.new()
	_overlay.name = "GiraDispositivo"
	_overlay.layer = 128
	_overlay.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_overlay)

	_panel = Control.new()
	_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_overlay.add_child(_panel)

	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color("#0a2540")
	_panel.add_child(bg)

	var gradient := ColorRect.new()
	gradient.set_anchors_preset(Control.PRESET_FULL_RECT)
	gradient.color = Color(0.08, 0.33, 0.45, 0.55)
	_panel.add_child(gradient)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_panel.add_child(center)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 16)
	center.add_child(vbox)

	var icon := Label.new()
	icon.text = "📱  ↻"
	icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon.add_theme_font_size_override("font_size", 56)
	vbox.add_child(icon)

	var title := Label.new()
	title.text = "Gira tu dispositivo"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color("#f4e4bc"))
	vbox.add_child(title)

	var body := Label.new()
	body.text = "Manta se juega en horizontal.\nGira el teléfono para continuar."
	body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_theme_font_size_override("font_size", 16)
	body.add_theme_color_override("font_color", Color("#adb5bd"))
	vbox.add_child(body)

	_overlay.visible = false
