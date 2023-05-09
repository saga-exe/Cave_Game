extends Area2D

onready var HUD = get_node("/root/MainScene/HUD")
onready var player = get_node("/root/MainScene/Adventurer")

func _ready() -> void:
	$AnimatedSprite.play("default") #spriten snurrar långsamt runt
	$Size.play("Default") #denna animationplayer ska spela effekten då hjärtat plockas upp, men nu gör den ingenting


func _physics_process(_delta: float) -> void:
	if Globals.is_finished: #då leveln avslutas (avklarad eller game over) startas en timer för att leveln och allt i den inte ska försvinna direkt. Då timern tar slut så försvinner allt
		$FinishTimer.start()


#Då timern stannar så tas hjärtat bort
func _on_FinishTimer_timeout():
	queue_free()


func _on_Heart_body_entered(body: Node) -> void:
	if body.is_in_group("Player"): #då spelaren plockar upp hjärtat spelas ett ljud, hp går upp och en effekt spelas. Då effekten är klar tas scenen bort
		$Pickup.play()
		$Size.play("Downsize")
		player.heal(25)
		yield($Size, "animation_finished")
		queue_free()
		
		

