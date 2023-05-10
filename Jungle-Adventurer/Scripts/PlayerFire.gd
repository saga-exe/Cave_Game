extends Area2D

var velocity = 1000
var direction := Vector2.ZERO

var explosion_scene = preload("res://Scenes/BulletExplosion.tscn")


func _ready() -> void:
	$FireTimer.start() #timer startas då scenen instansieras. då timern tar stopp så brinner kulan upp
	$AnimatedSprite.play("Travelling") #spelar animation för att kulan färdas
	$Travel.play() #spelar en brinnande ljudeffekt
	


func _physics_process(delta: float) -> void:
	global_position += velocity * delta * direction #gör att kulan rör sig frammåt
	if Globals.is_finished: #Då leveln avslutas (avklaras eller game over) så tas elden bort
		queue_free()


"""
anropas i Adventurer-scriptet då kulan instansieras för att bestämma rikting
"""
func set_direction(pos1: Vector2, pos2: Vector2) -> void:
	direction = (pos2 - pos1).normalized()
	rotation = direction.angle()


"""
Då timern tar slut stannar kulan och det spelas en animation så att kulan brinner upp.
Bränningen byter håll beroende på vilket håll kulan kommer ifrån. Då animationen är
klar så tas scenen bort från scenträdet.
"""
func _on_FireTimer_timeout() -> void:
	velocity = 0
	if direction.x < 0:
		$AnimatedSprite.set_flip_v(true)
	$AnimatedSprite.play("Exlpodes")
	yield($AnimatedSprite, "animation_finished")
	queue_free()


"""
Då något kommer in i kulans area så kollar denna funktion om det är en fiende.
Då exploderar kulan genom att instansiera en explosionsscen. Kulans CollisionShape
stängs också av för att den inte ska kollidera med något annat. Beroende på fiende
så tar  de olika mycket damage. Denna funktion anropar då damage-funktionen hos den
fiende som träffats. Kulan stannar och raderas sedan ur scenträdet.

Fiender är det enda spelarens attacker kolliderar med.
"""
func _on_PlayerFire_body_entered(body: Node) -> void:
	var damage = 0
	if body.is_in_group("Enemy"):
		var explosion_instance = explosion_scene.instance()
		$CollisionShape2D.set_deferred("disabled", true)
		if body.is_in_group("WraithOrange"):
			damage = 50
		elif body.is_in_group("WraithTeal"):
			damage = 70
		body.take_damage(damage)
		velocity = 0
		get_tree().get_root().call_deferred("add_child", explosion_instance)
		explosion_instance.global_position = global_position
		queue_free()

