extends Area2D

onready var player = get_node("/root/MainScene/Adventurer")
var lower_sound := false

func _ready():
	$Light2D.visible = false
	$AnimatedSprite.play("Unlit")


func _on_Checkpoint_body_entered(body):
	if body.is_in_group("Player"):
		$SoundTimer.start()
		$AudioStreamPlayer.play()
		$Light2D.visible = true
		$AnimatedSprite.play("Lit")
		player.last_pos = global_position


func _physics_process(_delta: float) -> void:
	if lower_sound:
		$AudioStreamPlayer.volume_db -= 0.1
	if Globals.is_finished:
		$FinishTimer.start()


func _on_FinishTimer_timeout():
	queue_free()


func _on_SoundTimer_timeout() -> void:
	lower_sound = true
