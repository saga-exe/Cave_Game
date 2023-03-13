extends Node2D


func _physics_process(delta: float) -> void:
	if Globals.is_finished:
		queue_free()
