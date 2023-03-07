extends Area2D

const VELOCITY = 2000

var direction := Vector2.ZERO


func _ready() -> void:
	$BulletTimer.start()
	


func _physics_process(delta: float) -> void:
	global_position += VELOCITY * delta * direction
	if Globals.finished():
		queue_free()


func set_direction(pos1: Vector2, pos2: Vector2) -> void:
	direction = (pos2 - pos1).normalized()
	rotation = direction.angle()


func _on_BulletTimer_timeout() -> void:
	queue_free()


func _on_Bullet_body_entered(body: Node) -> void:
	if body.is_in_group("Enemy"):
		body.die()

