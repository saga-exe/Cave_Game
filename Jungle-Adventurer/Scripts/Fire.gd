extends KinematicBody2D



var lower := true


func _ready():
	$AnimatedSprite.play("default")



func _physics_process(delta: float) -> void:
	if Globals.is_finished:
		$FinishTimer.start()


func _on_FinishTimer_timeout():
	queue_free()

