extends Area2D

const VELOCITY = 1500

var direction := Vector2.ZERO


func _ready() -> void:
	$FireTimer.start()
	print("instance")


func _physics_process(delta: float) -> void:
	global_position += VELOCITY * delta * direction


func set_direction(pos1: Vector2, pos2: Vector2) -> void:
	direction = (pos2 - pos1).normalized()
	rotation = direction.angle()


func _on_FireTimer_timeout() -> void:
	queue_free()


func _on_PlayerFire_body_entered(body: Node) -> void:
	if body.is_in_group("Enemy"):
		body.die()
		queue_free()

