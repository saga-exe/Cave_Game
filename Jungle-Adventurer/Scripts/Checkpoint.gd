extends Area2D

onready var player = get_node("/root/MainScene/Adventurer")

func _ready():
	$Light2D.visible = false
	$AnimatedSprite.play("Unlit")


func _on_Checkpoint_body_entered(body):
	if body.is_in_group("Player"):
		$Light2D.visible = true
		$AnimatedSprite.play("Lit")
		player.last_pos = global_position


func _physics_process(_delta: float) -> void:
	if Globals.is_finished:
		$FinishTimer.start()


func _on_FinishTimer_timeout():
	queue_free()
