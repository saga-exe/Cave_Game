extends Area2D

const VELOCITY = 500

var direction := Vector2.ZERO


func _ready() -> void:
	$Timer.start()
	$Sound.play()


func _physics_process(delta: float) -> void:
	global_position += VELOCITY * delta * direction
	if Globals.is_finished:
		queue_free()


func set_direction(pos1: Vector2, pos2: Vector2) -> void:
	direction = (pos2 - pos1).normalized()
	rotation = direction.angle()


func _on_Timer_timeout():
	queue_free()

func die() -> void:
	queue_free()

func _on_WraithBullet_body_entered(body):
	if body.is_in_group("Player"):
		var damage = 20
		var knockback_direction = 0
		body.take_damage(damage, knockback_direction)
		die()
