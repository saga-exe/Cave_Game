extends CPUParticles2D


func _ready() -> void:
	one_shot = true
	$AudioStreamPlayer.play()
	$AnimationPlayer.play("Explode")


func _process(_delta):
	if not is_emitting():
		queue_free()
