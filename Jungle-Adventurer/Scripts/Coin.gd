extends Area2D

onready var HUD = get_node("/root/MainScene/HUD")


func _ready() -> void:
	$AnimatedSprite.play("Idle")


func _physics_process(_delta: float) -> void:
	if Globals.is_finished:
		$FinishTimer.start()


func _on_FinishTimer_timeout():
	queue_free()



func _on_Coin_body_entered(body: Node) -> void:
	if body.is_in_group("Player"):
		queue_free()
		HUD.gems_collected(1)
		Globals.difficulty -= 0.05

