extends Node2D


func _physics_process(delta: float) -> void:
	if Globals.finished():
		queue_free()
