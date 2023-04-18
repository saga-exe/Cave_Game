extends Area2D

var velocity = 500
var direction := Vector2.ZERO

var explosion_scene = preload("res://Scenes/BulletExplosion.tscn")


func _ready() -> void:
	$FireTimer.start()
	$AnimatedSprite.play("Travelling")
	$SoundEffect.play()
	


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
	var explosion_instance = explosion_scene.instance()
	get_tree().get_root().call_deferred("add_child", explosion_instance)
	explosion_instance.global_position = global_position
	queue_free()


func _on_PlayerFireExtra_body_entered(body: Node) -> void:
	var damage = 0
	if body.is_in_group("Enemy"):
		var explosion_instance = explosion_scene.instance()
		if body.is_in_group("WraithOrange"):
			damage = 100
		elif body.is_in_group("WraithTeal"):
			damage = 100
		body.take_damage(damage)
		if direction.x < 0:
			$AnimatedSprite.set_flip_v(true)
		get_tree().get_root().call_deferred("add_child", explosion_instance)
		explosion_instance.global_position = global_position


