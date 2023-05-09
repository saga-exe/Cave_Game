extends Node2D


func _physics_process(_delta: float) -> void:
	if Globals.is_finished: #då leveln avslutas (avklarad eller game over) startas en timer för att leveln och allt i den inte ska försvinna direkt. Då timern tar slut så försvinner allt
		$FinishTimer.start()

#Då timern stannar så tas leveln bort
func _on_FinishTimer_timeout():
	queue_free()
