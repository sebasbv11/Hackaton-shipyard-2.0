extends Button

@export var escena_principal: PackedScene

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pressed.connect(jugar, 4)


func jugar():
	if has_node("/root/ControladorGlobal"):
		ControladorGlobal.reiniciar_progreso_minijuegos()
	if has_node("/root/GameManager"):
		GameManager.reset()
	get_tree().change_scene_to_packed(escena_principal)
