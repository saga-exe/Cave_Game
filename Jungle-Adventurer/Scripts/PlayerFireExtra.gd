extends Area2D

var velocity = 500

var direction := Vector2.ZERO


func _ready() -> void:
	$FireTimer.start()
	$AnimatedSprite.play("Travelling")
	


func _physics_process(delta: float) -> void:
	global_position += velocity * delta * direction
	if Globals.is_finished:
		queue_free()


func set_direction(pos1: Vector2, pos2: Vector2) -> void:
	direction = (pos2 - pos1).normalized()
	rotation = direction.angle()


func _on_FireTimer_timeout() -> void:
	velocity = 0
	if direction.x < 0:
		$AnimatedSprite.set_flip_v(true)
	$AnimatedSprite.play("Explodes")
	yield($AnimatedSprite, "animation_finished")
	queue_free()


func _on_PlayerFireExtra_body_entered(body: Node) -> void:
	var damage = 0
	if body.is_in_group("Enemy"):
		if body.is_in_group("WraithOrange"):
			damage = 100
		elif body.is_in_group("WraithTeal"):
			damage = 100
		body.take_damage(damage)
		if direction.x < 0:
			$AnimatedSprite.set_flip_v(true)


