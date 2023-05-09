extends Area2D

onready var HUD = get_node("/root/MainScene/HUD")
onready var player = get_node("/root/MainScene/Adventurer")

func _ready() -> void:
	$AnimatedSprite.play("default")
	$Size.play("Default")


func _physics_process(_delta: float) -> void:
	if Globals.is_finished: #då leveln avslutas (avklarad eller game over) startas en timer för att leveln och allt i den inte ska försvinna direkt. Då timern tar slut så försvinner allt
		$FinishTimer.start()


func _on_FinishTimer_timeout(): #Då timern stannar så tas powerup bort
	queue_free()



func _on_Star_body_entered(body: Node) -> void:
	if body.is_in_group("Player"):
		$Pickup.play()
		$Size.play("Downsize")
		player.power_up("star")
		yield($Size, "animation_finished")
		queue_free()
		
