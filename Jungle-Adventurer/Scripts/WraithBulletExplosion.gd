extends CPUParticles2D


func _ready(): #startar visuellt explosionen och ljudeffekten
	emitting = true
	$Sound.play()


func _physics_process(_delta):
	if not emitting: #då explosionen är över så raderas scenen från scenträdet
		queue_free()
