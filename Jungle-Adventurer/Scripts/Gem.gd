extends Area2D

func _ready() -> void:
	global_position = Vector2(500,450)


func _on_Gem_body_entered(body: Node) -> void:
	if body.is_in_group("Player"):
		queue_free()
