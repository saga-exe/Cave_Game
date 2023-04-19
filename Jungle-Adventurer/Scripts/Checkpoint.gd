extends Area2D

onready var player = get_node("/root/MainScene/Adventurer")
var lower_sound := false
var lit := false

func _ready():
	$Light2D.visible = false
	$AnimatedSprite.play("Unlit")


func _on_Checkpoint_body_entered(body):
	if body.is_in_group("Player") and not lit:
		$SoundTimer.start()
		$LightFire.play()
		$Light2D.visible = true
		$AnimatedSprite.play("Lit")
		player.last_pos = global_position
		lit = true


func _physics_process(_delta: float) -> void:
	if lower_sound and not $Fire.playing:
		$Fire.play()
	if $Fire.playing and $Fire.volume_db < 6:
		$Fire.volume_db += 0.1
	if lower_sound:
		$LightFire.volume_db -= 0.1
	if Globals.is_finished:
		$FinishTimer.start()


func _on_FinishTimer_timeout():
	queue_free()


func _on_SoundTimer_timeout() -> void:
	lower_sound = true
