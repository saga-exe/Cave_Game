extends CPUParticles2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	emitting = true
	$Sound.play()


func _physics_process(_delta):
	if not emitting:
		queue_free()
