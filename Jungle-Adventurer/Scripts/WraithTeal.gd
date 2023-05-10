extends KinematicBody2D

# it doesn't wait after knockback
# drops to die from idle to chase - fixed

#fix jump on head
#fix direction change after knockback

enum {IDLE, CHASE, DIE}


const ACCELERATION = 500
var GRAVITY = 1000
var IDLE_SPEED = rand_range(10, 30)  #randomiserad hastighet då fienden inte jagar efter spelaren
var CHASE_SPEED = rand_range(40, 60) #randomiserad hastighet då fienden jagar efter spelaren

var MAX_SPEED = 20
var velocity = Vector2.ZERO
var direction = Vector2.LEFT
var state = IDLE
var last_direction = 1 #sista hållet wraithen var vänd åt, men räknas inte om direction.x var 0
var knockback_direction = 1 #det håll spelaren åker åt när de kolliderar. alltså åker wraithen åt-knockback_direction då de kolliderar
var hp = 100
var difficulty = 0

var turn := false  #om true så ska wraithen vända om och gå tillbaka andra hållet
var wait := false #är bara true i CHASE state då wraithen kommer till slutet av en platform
var knockback := false #är true då wraithen har colliderat med spelaren och slås tillbaka
var can_check_right := true #används för att se om wraithen kan lita på den högra TerrainCheck
var can_check_left := true #används för att se om wraithen kan lita på den vänstra TerrainCheck
var can_attack := true #för att wraithen inte ska attackera hela tiden så har den en cooldown timer. då can_attack är true så kan den attackera
var can_drop_coin := true #används för att endast en peng ska spawna då wraithen dör

var bullet_scene = preload("res://Scenes/WraithBullet.tscn")
var coin_scene = preload("res://Scenes/Coin.tscn")

onready var player = get_node("/root/MainScene/Adventurer")
onready var TerrainCheck = $TerrainCheck
onready var TerrainCheck2 = $TerrainCheck2
onready var sprite = $AnimatedSprite


"""
_ready()-funktionen startar wraithens ylande ljud, sätter högsta fart till det
den ska ha i IDLE state. Den sätter också state till IDLE och spelar animationen
för IDLE. Eftersom den inte har tagit skada så har den ingen synlig healthbar.
"""
func _ready():
	$Default.play()
	MAX_SPEED = IDLE_SPEED
	state = IDLE
	sprite.play("Idle")
	$HealthBar.visible = false
	difficulty = Globals.difficulty


"""
_can_collide() ser till så att rätt areor och CollisionShapes är enabled
oavsett vad som händer. FUnktionen matchar också states så att det blir rätt.

Då spelaren plockat upp en star powerup så kan wraithen inte skjuta, men om spelaren
inte har det och attacktimern inte har någon tid kvar så kan den det.
"""
func _physics_process(delta: float) -> void:
	_can_collide()
	if Globals.power == "star":
		can_attack = false
	elif $ShootTimer.time_left <= 0:
		can_attack = true
	if Globals.is_finished or global_position.y > 600: #Då leveln avslutas (avklaras eller game over) så tas wraithen bort
		queue_free()
	match state:
		IDLE:
			_idle_state(delta)
		CHASE:
			_chase_state(delta)
		DIE:
			_die_state(delta)


"""
Denna funktion returnerar direction.x.
"""
func _update_direction_x(_delta) -> float:
	var player_slime_distance = player.global_position - global_position
	"""
	Då state == IDLE så gör funktionen ingenting om inte turn är true, i vilket
	fall den byter direction.x till det motsatta, vilket gör att wraithen vänder om.
	"""
	if state == IDLE:
		if turn:
			if last_direction > 0:
				direction.x = -1
			else:
				direction.x = 1
			turn = false
			
	elif state == CHASE:
		if (not can_check_left and velocity.x < 0) or (not can_check_right and velocity.x > 0): #ifall TerrainCheck är utanför plattformen åt det håll wraithen åker så stannar den
			wait = true
		if player_slime_distance.x < 5 and player_slime_distance.x > -5: #då spelaren är rakt ovanför eller under wraithen så står den stilla utan att byta riktning
			direction.x = 0
		elif player_slime_distance.x < 0: #om spelaren är till vänster om wraithen så åker den till vänster mot spelaren
			direction.x = -1
		else: #om spelaren är till höger om wraithen så åker den till höger mot spelaren
			direction.x = 1
		
		if wait:
			"""
			om wraithen står stilla vid kanten av en platform och en raycast känner
			av en platform under så kan wraithen gå av kanten och veta att den
			kommer att landa på mark, alltså sätts wait till false
			"""
			velocity.x = 0
			"""
			eftersom direction.x räknas ut varje gång så har vi ett värde på
			direction.x != 0. om det är samma som last_direction betyder det
			att wraithen ska stå kvar på samma ställe, och direction.x blir
			0, eftersom det betyder att den inte kommer att röra på sig.
			
			Om de inte är samma betyder det att wraithen ska vända på sig
			och därför blir wait false
			"""
			if last_direction == direction.x:
				direction.x = 0
			else:
				wait = false
	
	#last_direction kan inte vara noll, men den uppdateras om den kan
	if direction.x != 0:
		last_direction = direction.x

	return direction.x


func _basic_movement(delta) -> void:
	if direction.x != 0:
		velocity = velocity.move_toward(direction*MAX_SPEED, ACCELERATION*delta)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, ACCELERATION*delta)
	velocity.y += GRAVITY*delta
	velocity = move_and_slide(velocity, Vector2.UP)
	
	_sprite_direction()

func _sprite_direction() -> void:
	if knockback:
		if knockback_direction > 0:
			_sprite_right()
		else:
			_sprite_left()
			
	else:
		if velocity.x == 0:
			if last_direction < 0:
				_sprite_left()
			else:
				_sprite_right()
		elif velocity.x < 0:
			_sprite_left()
		else:
			_sprite_right()


func _sprite_right() -> void:
	sprite.set_flip_h(false)
	$CastPoint.position.x = 10


func _sprite_left() -> void:
	sprite.set_flip_h(true)
	$CastPoint.position.x = -10


func _idle_state(delta) -> void:
	MAX_SPEED = IDLE_SPEED
	direction.x = _update_direction_x(delta)
	
	_basic_movement(delta)
	
	#vector så att det blir en båge
	var player_slime_distance = player.global_position - global_position
	if player_slime_distance.length() <= 400 and not Globals.damaged:
		sprite.play("Walking")
		state = CHASE
		return
# if cant check left and velocity < 0 wait = true

func _chase_state(delta) -> void:
	if wait:
		sprite.play("Idle")
	else:
		sprite.play("Walking")
	MAX_SPEED = CHASE_SPEED
	
	direction.x = _update_direction_x(delta)
	
	_basic_movement(delta)
	_attack()
	
	#vector så att det blir en båge
	var player_slime_distance = player.global_position - global_position
	
	if player_slime_distance.length() >= 400 or Globals.damaged:
		sprite.play("Walking")
		if wait:
			wait = false
			turn = true
		state = IDLE
		return


func _die_state(_delta) -> void:
	$HealthBar.visible = true
	$HealthBar.value = 0
	$TopKill/TopKillArea/CollisionShape2D.disabled = true
	$TileCollision.disabled = true
	$KinematicBody2D/PlayerCollision.disabled = true
	$WraithArea/CollisionShape2D.disabled = true
	$TopKill/CollisionShape2D.disabled = true
	set_collision_mask_bit(8, false)
	velocity.x = 0
	direction.x = 0
	if not $Death.playing:
		$Death.play()
	sprite.play("Dying")
	$Default.volume_db -= 1
	yield(sprite,"animation_finished")
	if can_drop_coin:
		var coin_instance = coin_scene.instance()
		get_tree().get_root().call_deferred("add_child", coin_instance)
		coin_instance.global_position = Vector2(global_position.x, global_position.y - 20)
		can_drop_coin = false
	queue_free()

#turn behövs enbart då enemy ska vända vid slutet av en platform,
#ej då spelaren hamnar på andra sidan

"""
_on_Area2D_body_exited() kollar ifall TerrainCheck/TerrainCheck2 har lämnat platformen, aka slimen är påväg att åka av
- ifall state == IDLE ska turn vara true, wait false och can_drop false
- ifall state == CHASE ska turn vara false, och sedan cecka för platformar under och då bestämma om wait eller drop är true
- då drop == true så är (turn och wait) == false
- den droppar eftersom den aldrig kommer in på platformen och därför går inte terrancheck ut och stoppar slimen från att trilla
"""



func _on_WraithArea_body_entered(body: Node) -> void:
	if body.is_in_group("Player"):
		if (body.global_position.y - global_position.y) > 24 and Globals.y_move == -1:
			$TileCollision.set_deferred("disabled", true)
			$KinematicBody2D/PlayerCollision.set_deferred("disabled", true)
			$WraithArea/CollisionShape2D.set_deferred("disabled", true)
			state = DIE
			body.take_damage(25, 0)
		else:
			knockback = true
			$KnockBackTimer.start()
			if player.global_position.x - global_position.x < 0:
				knockback_direction = -1
			else:
				knockback_direction = 1
			body.take_damage(25, knockback_direction)
			velocity.x = knockback_direction * -200

# terraincheck decides if turn or not, then state decides if turn or wait, and after state it should be decided if it drops or not ( raycast )

# det är om raycast är kortare än avståndet mellan slime och nedre kanten på skärmen som den kan droppa, ANNARS INTE


func _on_TerrainArea_body_entered(body):
	if body.is_in_group("Tile"):
		can_check_right = true


func _on_TerrainArea2_body_entered(body):
	if body.is_in_group("Tile"):
		can_check_left = true


func _on_TerrainArea_body_exited(body):
	if body.is_in_group("Tile"):
		if state == IDLE:
			turn = true
		elif state == CHASE:
			turn = false
			wait = true
	can_check_right = false


func _on_TerrainArea2_body_exited(body):
	if body.is_in_group("Tile"):
		if state == IDLE:
			turn = true
		elif state == CHASE:
			wait = true
	can_check_left = false


func _attack() -> void:
	if can_attack:
		var target = Vector2(player.global_position.x, player.global_position.y)
		sprite.play("SpellCast")
		var bullet_instance = bullet_scene.instance()
		bullet_instance.global_position = $CastPoint.global_position
		bullet_instance.set_direction($CastPoint.global_position, target)
		get_tree().get_root().add_child(bullet_instance)
		$ShootTimer.start()
		can_attack = false


func _on_ShootTimer_timeout():
	can_attack = true


func take_damage(damage) -> void:
	hp -= damage * (2- difficulty)
	$HealthBar.value = hp
	if hp < 100:
		$HealthBar.visible = true
	else:
		$HealthBar.visible = false
	if hp <= 0:
		state = DIE


func _on_TopKillArea_body_entered(body):
	if body.is_in_group("Player"):
		GRAVITY = 0
		knockback = true
		if player.global_position.x - global_position.x < 0:
			knockback_direction = -1
		else:
			knockback_direction = 1
		body.take_damage(0, knockback_direction)
		state = DIE


func _can_collide() -> void:
	if global_position.y - player.global_position.y >= 48 and Globals.y_move != -1:
		$TopKill.set_collision_layer_bit(10, true)
		$TopKill/CollisionShape2D.disabled = false
		$TopKill/TopKillArea/CollisionShape2D.disabled = false
	else:
		$TopKill.set_collision_layer_bit(10, false)
		$TopKill/CollisionShape2D.disabled = true
		$TopKill/TopKillArea/CollisionShape2D.disabled = true
	if not Globals.can_collide:
		$KinematicBody2D/PlayerCollision.disabled = true
		$WraithArea/CollisionShape2D.disabled = true
	else:
		$KinematicBody2D/PlayerCollision.disabled = false
		$WraithArea/CollisionShape2D.disabled = false
	if Globals.y_move == -1:
		$KinematicBody2D/PlayerCollision.disabled = true


func _on_KnockBackTimer_timeout():
	knockback = false


func _on_WraithArea_body_exited(body: Node) -> void:
	if body.is_in_group("Player"):
		$TopKill/CollisionShape2D.set_deferred("disabled", false)
		$TopKill/TopKillArea/CollisionShape2D.set_deferred("disabled", false)
