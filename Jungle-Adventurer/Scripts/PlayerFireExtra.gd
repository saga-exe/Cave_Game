extends Area2D

var velocity = 500
var direction := Vector2.ZERO

var explosion_scene = preload("res://Scenes/BulletExplosion.tscn")


func _ready() -> void:
	$FireTimer.start() #timer startas då scenen instansieras. då timern tar stopp så brinner attacken upp
	$AnimatedSprite.play("Travelling") #spelar animation för att ttacken färdas
	$SoundEffect.play() #spelar en brinnande ljudeffekt
	


func _physics_process(delta: float) -> void:
	global_position += velocity * delta * direction #gör att attacken rör sig frammåt
	if Globals.is_finished: #Då leveln avslutas (avklaras eller game over) så tas elden bort
		queue_free()


"""
anropas i Adventurer-scriptet då attacken instansieras för att bestämma rikting
"""
func set_direction(pos1: Vector2, pos2: Vector2) -> void:
	direction = (pos2 - pos1).normalized()
	rotation = direction.angle()


"""
Då timern tar slut stannar elden och en explosionsscen instansieras. Scenen tas
bort från scenträdet.
"""
func _on_FireTimer_timeout() -> void:
	velocity = 0
	var explosion_instance = explosion_scene.instance()
	get_tree().get_root().call_deferred("add_child", explosion_instance)
	explosion_instance.global_position = global_position
	queue_free()

"""
Då något kommer in i eldens area så kollar denna funktion om det är en fiende.
Då dör fienden direkt eftersom denna funktion anropar damage-funktionen hos den
fiende som träffats och sätter damage som hela fiendens hp. En explosionsscen
instansieras för att markera att fienden har blivit träffad.

Fiender är det enda spelarens attacker kolliderar med.
"""
func _on_PlayerFireExtra_body_entered(body: Node) -> void:
	var damage = 0
	if body.is_in_group("Enemy"):
		var explosion_instance = explosion_scene.instance()
		if body.is_in_group("WraithOrange"):
			damage = 100
		elif body.is_in_group("WraithTeal"):
			damage = 100
		body.take_damage(damage)
		get_tree().get_root().call_deferred("add_child", explosion_instance)
		explosion_instance.global_position = global_position


