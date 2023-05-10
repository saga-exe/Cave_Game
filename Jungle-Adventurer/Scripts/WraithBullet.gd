extends Area2D

const VELOCITY = 500
var direction := Vector2.ZERO

var explosion_scene = preload("res://Scenes/WraithBulletExplosion.tscn")


func _ready() -> void:
	$Timer.start()  #timer startas då scenen instansieras. då timern tar stopp så tas scenen bort från scenträdet
	$Sound.play() #spelar en brinnande ljudeffekt


func _physics_process(delta: float) -> void:
	global_position += VELOCITY * delta * direction #gör att den blå elden rör sig frammåt
	if Globals.is_finished: #Då leveln avslutas (avklaras eller game over) så tas elden bort
		queue_free()


"""
anropas i Adventurer-scriptet då kulan instansieras för att bestämma rikting
"""
func set_direction(pos1: Vector2, pos2: Vector2) -> void:
	direction = (pos2 - pos1).normalized()
	rotation = direction.angle()


func _on_Timer_timeout(): #då timern tar slut så tas den blå elden bort ur scenträdet.
	queue_free()


"""
Ifall spelaren kommer in i eldens area så anropar denna funktion spelarens damage-
funktion så att den tar damage. Den instansierar också en explosion.
"""
func _on_WraithBullet_body_entered(body):
	if body.is_in_group("Player"):
		var explosion_instance = explosion_scene.instance()
		body.take_damage(20, 0)
		get_tree().get_root().call_deferred("add_child", explosion_instance)
		explosion_instance.global_position = global_position
		queue_free()
