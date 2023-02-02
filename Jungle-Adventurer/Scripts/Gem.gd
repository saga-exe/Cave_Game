extends Area2D

onready var HUD = get_node("/root/MainScene/HUD")

func _ready() -> void:
	global_position = Vector2(500,450)


func _on_Gem_body_entered(body: Node) -> void:
	if body.is_in_group("Player"):
		queue_free()
		var gem = 1
		HUD.gems_collected(gem)
