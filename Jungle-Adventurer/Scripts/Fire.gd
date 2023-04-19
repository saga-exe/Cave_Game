extends KinematicBody2D




func _ready():
	$AnimatedSprite.play("default")
	$Fire.play()



func _physics_process(_delta: float) -> void:
	if Globals.is_finished:
		$FinishTimer.start()


func _on_FinishTimer_timeout():
	queue_free()

