extends Area2D


func _ready():
	$Size.play("Default")

func _physics_process(_delta: float) -> void:
	if Globals.is_finished:
		$FinishTimer.start()



func _on_Gem_body_entered(body):
	if body.is_in_group("Player"):
		$Pickup.play()
		$Size.play("Downsize")
		Globals.difficulty -= 0.2
		yield($Size, "animation_finished")
		queue_free()
		


func _on_FinishTimer_timeout():
	queue_free()
