extends Area2D




func _physics_process(_delta: float) -> void:
	if Globals.is_finished:
		$FinishTimer.start()



func _on_Gem_body_entered(body):
	if body.is_in_group("Player"):
		queue_free()
		Globals.difficulty -= 0.2


func _on_FinishTimer_timeout():
	queue_free()
