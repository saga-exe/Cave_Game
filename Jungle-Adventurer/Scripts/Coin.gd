extends Area2D

onready var HUD = get_node("/root/MainScene/HUD")

func _ready() -> void:
	$AnimatedSprite.play("Idle")


func _on_Coin_body_entered(body: Node) -> void:
	if body.is_in_group("Player"):
		queue_free()
		var coins = 1
		HUD.gems_collected(coins)
