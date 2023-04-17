extends Area2D

var velocity = 1000

var direction := Vector2.ZERO


func _ready() -> void:
	$FireTimer.start()
	$AnimatedSprite.play("Travelling")
	$AudioStreamPlayer.play()
	


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
	$AnimatedSprite.play("Exlpodes")
	yield($AnimatedSprite, "animation_finished")
	queue_free()


func _on_PlayerFire_body_entered(body: Node) -> void:
	var damage = 0
	if body.is_in_group("Enemy"):
		$CollisionShape2D.set_deferred("disabled", true)
		if body.is_in_group("WraithOrange"):
			damage = 50
		elif body.is_in_group("WraithTeal"):
			damage = 70
		body.take_damage(damage)
		velocity = 0
		if direction.x < 0:
			$AnimatedSprite.set_flip_v(true)
		$AnimatedSprite.play("Exlpodes")
		yield($AnimatedSprite, "animation_finished")
		queue_free()

