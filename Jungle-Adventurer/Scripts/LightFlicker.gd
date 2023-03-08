extends Light2D

var lower := true
var scale_change = rand_range(0.05,0.1)
var energy_change = rand_range(0.03,0.08)

func _ready():
	energy = rand_range(0.95, 1.05)
	

func _physics_process(delta: float) -> void:
	if lower and energy > 0.95:
		energy -= energy_change * delta
		scale.x -= scale_change*delta
		scale.y -= scale_change*delta
	elif lower:
		lower = false
	elif not lower and energy < 1.05:
		energy += energy_change * delta
		scale.x += scale_change*delta
		scale.y += scale_change*delta
	else:
		lower = true

