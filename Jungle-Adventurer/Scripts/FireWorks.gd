extends CPUParticles2D


func _ready() -> void:
	one_shot = true
	$AudioStreamPlayer.play() #ljudet spelas
	$AnimationPlayer.play("Explode") #animation spelas


func _process(_delta):
	if not is_emitting(): #då fyrverkeriet är klart så tas scenen bort ur scenträdet
		queue_free()
