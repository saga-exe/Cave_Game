extends Area2D

const VELOCITY = 2000

var direction := Vector2.ZERO


func _ready() -> void:
	$Timer.start()


func _physics_process(delta: float) -> void:
	#if direction == Vector2.ZERO:
		#return
	
	#else:
	global_position += VELOCITY * delta * direction


func set_direction(pos1: Vector2, pos2: Vector2) -> void:
	direction = (pos2 - pos1).normalized()
	rotation = direction.angle()


func _on_Bullet_body_entered(body: Node) -> void:
	if body.is_in_group("Enemy"):
		body.die()
		queue_free()
	elif body.is_in_group("Tile"):
		queue_free()


func _on_Timer_timeout() -> void:
	queue_free()




