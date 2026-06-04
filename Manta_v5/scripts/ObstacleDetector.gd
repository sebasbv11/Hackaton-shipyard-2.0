extends Area2D

@onready var player = get_parent()

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("obstaculo"):
		if player.has_method("golpear"):
			player.golpear()
