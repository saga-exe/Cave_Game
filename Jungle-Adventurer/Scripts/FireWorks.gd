extends CPUParticles2D


func _ready() -> void:
	one_shot = true
	$AudioStreamPlayer.play()


func _process(_delta):
	if not is_emitting():
		queue_free()
