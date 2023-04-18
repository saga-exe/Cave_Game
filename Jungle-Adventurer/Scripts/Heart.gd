extends Area2D

onready var HUD = get_node("/root/MainScene/HUD")
onready var player = get_node("/root/MainScene/Adventurer")

func _ready() -> void:
	$AnimatedSprite.play("default")
	$Size.play("Default")


func _physics_process(_delta: float) -> void:
	if Globals.is_finished:
		$FinishTimer.start()


func _on_FinishTimer_timeout():
	queue_free()



func _on_Heart_body_entered(body: Node) -> void:
	if body.is_in_group("Player"):
		$Pickup.play()
		$Size.play("Downsize")
		player.heal(25)
		yield($Size, "animation_finished")
		queue_free()
		
		

