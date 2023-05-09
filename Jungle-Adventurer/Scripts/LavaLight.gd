extends Light2D


var scale_change = rand_range(0.05,0.1)
var energy_change = rand_range(0.03,0.08)

var lower := true


func _ready() -> void:
	energy = rand_range(0.75, 0.85)
	

func _physics_process(delta: float) -> void:
	if lower and energy > 0.75:
		energy -= energy_change * delta
		scale.x -= scale_change*delta
		scale.y -= scale_change*delta
	elif lower:
		lower = false
	elif not lower and energy < 0.85:
		energy += energy_change * delta
		scale.x += scale_change*delta
		scale.y += scale_change*delta
	else:
		lower = true
	
	if Globals.is_finished: #då leveln avslutas (avklarad eller game over) startas en timer för att leveln och allt i den inte ska försvinna direkt. Då timern tar slut så försvinner allt
		$FinishTimer.start()


#Då timern stannar så tas ljuset bort
func _on_FinishTimer_timeout():
	queue_free()

	
