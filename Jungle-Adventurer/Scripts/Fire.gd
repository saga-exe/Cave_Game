extends KinematicBody2D



var lower := true


func _ready():
	$AnimatedSprite.play("default")



func _physics_process(delta: float) -> void:
	if Globals.finished():
		queue_free()
