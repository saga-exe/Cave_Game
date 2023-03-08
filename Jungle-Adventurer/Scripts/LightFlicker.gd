extends Light2D

var lower := true

func _ready():
	energy = rand_range(0.95, 1.05)

func _physics_process(delta: float) -> void:
	if lower and energy > 0.95:
		energy -= 0.05 * delta
		scale.x -= 0.15*delta
		scale.y -= 0.15*delta
	elif lower:
		lower = false
	elif not lower and energy < 1.05:
		energy += 0.05 * delta
		scale.x += 0.15*delta
		scale.y += 0.15*delta
	else:
		lower = true
