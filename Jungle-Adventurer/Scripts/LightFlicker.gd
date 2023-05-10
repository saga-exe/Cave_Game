extends Light2D

#detta script används för både dekorationseldar i levlar och för att göra ljuset
#runt musen mer levande i menyer

var lower := true #är true då eldens/musens energy minskar
var scale_change = rand_range(0.05,0.1) #randomiserar hur kraftigt och snabbt skalan på ljuset ska förändras
var energy_change = rand_range(0.03,0.08) #randomiserar hur kraftigt och snabbt energin hos ljuset ska förändras

func _ready(): #ger ett startvärde till ljusets energi
	energy = rand_range(0.95, 1.05)
	

"""
I denna funktion så minskar skala och energi om lower == true och energin inte
är för låg (> 0.95). Om energin är för låge men lower == true så blir lower
false och istället ökar skala och energi för ljuset.
"""
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

