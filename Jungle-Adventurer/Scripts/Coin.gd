extends Area2D

onready var HUD = get_node("/root/MainScene/HUD")

func _ready() -> void:
	$AnimatedSprite.play("Idle") #pengen snurrar långsamt
	$Size.play("Default") #pengen är sin vanliga storlek


func _physics_process(_delta: float) -> void:
	if Globals.is_finished: #då leveln avslutas (avklarad eller game over) startas en timer för att leveln och allt i den inte ska försvinna direkt. Då timern tar slut så försvinner allt
		$FinishTimer.start()


#Då timern stannar så tas pengen bort
func _on_FinishTimer_timeout():
	queue_free()



func _on_Coin_body_entered(body: Node) -> void:
	if body.is_in_group("Player"): #Då pengen tas upp av spelaren så spelas ljud, pengen minskar i storlek, antal coins ändras i HUDen och difficulty blir lite lägre
		$Pickup.play()
		$Size.play("Downsize")
		HUD.gems_collected(1)
		Globals.difficulty -= 0.004
		yield($Size, "animation_finished")
		queue_free() #pengen försvinner efter att animationen är klar
		

