extends Area2D

onready var HUD = get_node("/root/MainScene/HUD")
onready var player = get_node("/root/MainScene/Adventurer")

func _ready() -> void:
	$AnimatedSprite.play("default")


func _physics_process(delta: float) -> void:
	if Globals.is_finished:
		$FinishTimer.start()


func _on_FinishTimer_timeout():
	queue_free()



func _on_Star_body_entered(body: Node) -> void:
	if body.is_in_group("Player"):
		queue_free()
		player.power_up("star")
