extends RefCounted
class_name PlayerSprite

const SHEET_PATH := "res://assets/placeholders/characters/player_retro_sprite_sheet.png"
const CELL_W := 102.0
const CELL_H := 152.75

var texture: Texture2D = null
var frame_time := 0.0
var frame_index := 0
var facing := "down"
var is_moving := false

var animations := {
	"down": [
		Rect2(0, 0, CELL_W, CELL_H),
		Rect2(CELL_W, 0, CELL_W, CELL_H),
		Rect2(CELL_W * 2, 0, CELL_W, CELL_H),
		Rect2(CELL_W * 3, 0, CELL_W, CELL_H),
	],
	"left": [
		Rect2(0, CELL_H * 2, CELL_W, CELL_H),
		Rect2(CELL_W, CELL_H * 2, CELL_W, CELL_H),
		Rect2(CELL_W * 2, CELL_H * 2, CELL_W, CELL_H),
		Rect2(CELL_W * 3, CELL_H * 2, CELL_W, CELL_H),
	],
	"right": [
		Rect2(0, CELL_H * 3, CELL_W, CELL_H),
		Rect2(CELL_W, CELL_H * 3, CELL_W, CELL_H),
		Rect2(CELL_W * 2, CELL_H * 3, CELL_W, CELL_H),
		Rect2(CELL_W * 3, CELL_H * 3, CELL_W, CELL_H),
	],
	"up": [
		Rect2(0, CELL_H, CELL_W, CELL_H),
		Rect2(CELL_W, CELL_H, CELL_W, CELL_H),
		Rect2(CELL_W * 2, CELL_H, CELL_W, CELL_H),
		Rect2(CELL_W * 3, CELL_H, CELL_W, CELL_H),
	],
}

func _init() -> void:
	texture = _load_image_texture(SHEET_PATH)


func update(delta: float, axis: Vector2) -> void:
	is_moving = axis.length() > 0.05
	if abs(axis.x) > abs(axis.y):
		facing = "right" if axis.x > 0.0 else "left"
	elif abs(axis.y) > 0.05:
		facing = "down" if axis.y > 0.0 else "up"

	if is_moving:
		frame_time += delta
		if frame_time >= 0.14:
			frame_time = 0.0
			frame_index = (frame_index + 1) % animations[facing].size()
	else:
		frame_index = 0
		frame_time = 0.0


func draw(canvas: CanvasItem, pos: Vector2) -> void:
	if texture == null:
		_draw_fallback(canvas, pos)
		return

	var frames: Array = animations[facing]
	var source: Rect2 = frames[0]
	if is_moving:
		source = frames[frame_index]
	var dest_size := Vector2(76, 112)
	canvas.draw_texture_rect_region(
		texture,
		Rect2(pos.x - dest_size.x * 0.5, pos.y - dest_size.y + 30, dest_size.x, dest_size.y),
		source
	)


func _draw_fallback(canvas: CanvasItem, pos: Vector2) -> void:
	canvas.draw_rect(Rect2(pos.x - 18, pos.y + 0, 36, 40), Color("#e76f51"))
	canvas.draw_rect(Rect2(pos.x - 18, pos.y - 36, 36, 36), Color("#f4e4bc"))


func _load_image_texture(path: String) -> Texture2D:
	var image := Image.load_from_file(path)
	if image == null:
		return null
	_make_key_color_transparent(image)
	return ImageTexture.create_from_image(image)


func _make_key_color_transparent(image: Image) -> void:
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			var color := image.get_pixel(x, y)
			if color.r < 0.04 and color.g < 0.04 and color.b < 0.04:
				color.a = 0.0
				image.set_pixel(x, y, color)
