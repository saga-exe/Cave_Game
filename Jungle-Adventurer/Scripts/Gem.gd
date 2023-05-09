extends Area2D


func _ready():
	$Size.play("Default") #gemet är sin vanliga storlek

func _physics_process(_delta: float) -> void:
	if Globals.is_finished: #då leveln avslutas (avklarad eller game over) startas en timer för att leveln och allt i den inte ska försvinna direkt. Då timern tar slut så försvinner allt
		$FinishTimer.start()



func _on_Gem_body_entered(body):
	if body.is_in_group("Player"): #då spelaren plockar upp gemet spelas ett ljud, difficulty går ner och en effekt spelas. Då effekten är klar tas scenen bort
		$Pickup.play()
		$Size.play("Downsize")
		Globals.difficulty -= 0.2
		yield($Size, "animation_finished")
		queue_free()


#Då timern stannar så tas gemet bort
func _on_FinishTimer_timeout():
	queue_free()
