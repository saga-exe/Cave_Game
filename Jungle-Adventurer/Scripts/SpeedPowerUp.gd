extends Area2D

onready var HUD = get_node("/root/MainScene/HUD")
onready var player = get_node("/root/MainScene/Adventurer")

func _ready() -> void:
	$AnimatedSprite.play("default")


func _physics_process(delta: float) -> void:
	if Globals.finished():
		queue_free()


func _on_SpeedPowerUp_body_entered(body: Node) -> void:
	if body.is_in_group("Player"):
		queue_free()
		player.power_up("speed")
