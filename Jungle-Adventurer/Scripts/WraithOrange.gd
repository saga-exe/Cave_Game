extends KinematicBody2D

enum {IDLE, CHASE, DIE}


const ACCELERATION = 500
var IDLE_SPEED = rand_range(50, 70) #randomiserad hastighet då fienden inte jagar efter spelaren
var CHASE_SPEED = rand_range(80, 110) #randomiserad hastighet då fienden jagar efter spelaren
var GRAVITY = 1000

var MAX_SPEED = 40
var velocity = Vector2.ZERO
var direction = Vector2.LEFT
var state = IDLE
var last_direction = 1 #sista hållet wraithen var vänd åt, men räknas inte om direction.x var 0
var knockback_direction = 1 #det håll spelaren åker åt när de kolliderar. alltså åker wraithen åt-knockback_direction då de kolliderar
var hp = 100
var difficulty = 0

var turn := false #om true så ska wraithen vända om och gå tillbaka andra hållet
var wait := false #är bara true i CHASE state då wraithen kommer till slutet av en platform och det inte finns en platform under att hopp ner til
var knockback := false #är true då wraithen har colliderat med spelaren och slås tillbaka
var can_check_right := true #används för att se om wraithen kan lita på den högra TerrainCheck
var can_check_left := true #används för att se om wraithen kan lita på den vänstra TerrainCheck
var can_drop_coin := true #används för att endast en peng ska spawna då wraithen dör

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
	$Default.play() #ljud av ylande wraith
	MAX_SPEED = IDLE_SPEED
	state = IDLE
	sprite.play("Idle")
	$HealthBar.visible = false
	difficulty = Globals.difficulty


"""
_can_collide() ser till så att rätt areor och CollisionShapes är enabled
oavsett vad som händer. FUnktionen matchar också states så att det blir rätt.
"""
func _physics_process(delta: float) -> void:
	_can_collide()
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
			if (last_direction == 1 and (str($RayCast2D.get_collider()) != "[Object:null]")) or (last_direction == -1 and (str($RayCast2D2.get_collider()) != "[Object:null]")):
				wait = false
			else:
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


"""
Denna funktion tar hand om de grundläggande rörelserna. Den får wraithen att gå
eller stanna in beroende på direction.x, vilken bestäms i _update_direction_x().
Funktionen anropar även en annan funktion som ser till så att sprites är åt rätt håll.
"""
func _basic_movement(delta) -> void:
	if direction.x != 0:
		velocity = velocity.move_toward(direction*MAX_SPEED, ACCELERATION*delta)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, ACCELERATION*delta)
	velocity.y += GRAVITY*delta
	velocity = move_and_slide(velocity, Vector2.UP)
	
	_sprite_direction()


"""
Som hörs på namnet så bestämmer denna funktion åt vilket håll sprites ska vara.

Om knockback är true så är sprites i knockback_directions riktning.
Om wraithen står still så är sprites i last_directions riktning, och om den rör
sig utan knockback så är det åt vilket håll den rör sig som avgör åt vilket håll
sprites ska vara.
"""
func _sprite_direction() -> void:
	if knockback:
		if knockback_direction > 0:
			sprite.set_flip_h(false)
		else:
			sprite.set_flip_h(true)
			
	else:
		if velocity.x == 0:
			if last_direction < 0:
				sprite.set_flip_h(true)
			else:
				sprite.set_flip_h(false)
		elif velocity.x < 0:
			sprite.set_flip_h(true)
		else:
			sprite.set_flip_h(false)


func _idle_state(delta) -> void:
	#sätter rätt hastighet för _idle_state samt kör funktionen för direction.x och rörelse
	MAX_SPEED = IDLE_SPEED
	direction.x = _update_direction_x(delta)
	_basic_movement(delta)
	
	"""
	om spelaren är tillräckligt nära och inte nyss har tagit skada så ändras state
	"""
	var player_slime_distance = player.global_position - global_position
	if player_slime_distance.length() <= 400 and not Globals.damaged:
		sprite.play("Walking")
		state = CHASE
		return


func _chase_state(delta) -> void:
	#sätter rätt hastighet för _idle_state samt kör funktionen för direction.x och rörelse
	MAX_SPEED = CHASE_SPEED
	direction.x = _update_direction_x(delta)
	_basic_movement(delta)
	
	#beroende på om wraithen står still eller ej så spelas olika animationer
	if wait:
		sprite.play("Idle")
	else:
		sprite.play("Walking")
	
	"""
	om spelaren är för långt bort eller nyss har tagit skada så kan wraithen
	inte göra skada och övergår därför till _idle_state() igen. Den vänder då
	direkt om.
	"""
	var player_slime_distance = player.global_position - global_position
	if player_slime_distance.length() >= 400 or Globals.damaged:
		sprite.play("Walking")
		if wait:
			wait = false
			turn = true
		state = IDLE
		return


"""
Denna funktion anropas på olika ställen i detta script. Det anropas då hp <= 0,
då spelaren har hoppat på toppen av dess huvud eller hoppat upp i den underifrån.AABB

I funktionen så stängs flera olika CollisionShapes så att inget ska kollidera
med wraithen då den dör. Så fort hp <= så anses wraithen död. Därför sätts
direction.x och velocity.x till 0.

Då wraithen dör spelas ett döende ljud samt en döende animation. Sedan instansieras
en Coinscen, och då animationen av döendet så tas wraithen bort från scenträdet.
"""
func _die_state(_delta) -> void:
	$HealthBar.visible = true
	$HealthBar.value = 0
	$TopKill/TopKillArea/CollisionShape2D.disabled = true
	$TileCollision.disabled = true
	$KinematicBody2D/PlayerCollision.disabled = true
	$WraithArea/CollisionShape2D.disabled = true
	$TopKill/CollisionShape2D.disabled = true
	set_collision_mask_bit(8, false) #spelarens eld kommer inte att stoppas av denna wraith längre
	velocity.x = 0
	direction.x = 0
	if not $Death.playing:
		$Death.volume_db = 3
		$Death.pitch_scale = 1
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


"""
WraithArean kontrollerar enbart om det är spelaren som kommer in.
"""
func _on_WraithArea_body_entered(body: Node) -> void:
	if body.is_in_group("Player"):
		"""
		om avståndet mellan wraiths och spelares global_position är större än
		26 om spelaren rör sig uppåt in i WraithArea så betyder det att spelaren
		kommer underifrån. Då dör wraithen och spelaren tar skada.
		
		annars så har spelaren kolliderat med wraithen från sidan, i vilket fall
		de båda knockas tillbaka och spelarens damage-funktion anropas.
		"""
		if (body.global_position.y - global_position.y) > 26 and Globals.y_move == -1:
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

"""
då TerrainCheck är i tiles, allså plattformar, så betyder det att wraithen inte
är påväg att trilla av plattformen, och den kan även märka om TerrainChecken på
den sidan åker ur plattformen. Denna kontrollerar höger sida.
"""
func _on_TerrainArea_body_entered(body):
	if body.is_in_group("Tile"):
		can_check_right = true


"""
då TerrainCheck är i tiles, allså plattformar, så betyder det att wraithen inte
är påväg att trilla av plattformen, och den kan även märka om TerrainChecken på
den sidan åker ur plattformen. Denna kontrollerar vänster sida.
"""
func _on_TerrainArea2_body_entered(body):
	if body.is_in_group("Tile"):
		can_check_left = true


"""
Då TerrainCheck åker ur tiles så betyder det att det antingen är dags att vända,
stanna eller kolla om det finns plattformar under den nuvarande för att se om
det går att hoppa ner. Om state == IDLE så vänder wraithen, annars stannar den
'och det bestämms i en annan funktion ifall den ska fortsätta eller stå kvar.
Denna är för höger TerrainCheck.
"""
func _on_TerrainArea_body_exited(body):
	if body.is_in_group("Tile"):
		if state == IDLE:
			turn = true
		elif state == CHASE:
			turn = false
			wait = true
	can_check_right = false


"""
Då TerrainCheck åker ur tiles så betyder det att det antingen är dags att vända,
stanna eller kolla om det finns plattformar under den nuvarande för att se om
det går att hoppa ner. Om state == IDLE så vänder wraithen, annars stannar den
'och det bestämms i en annan funktion ifall den ska fortsätta eller stå kvar.
Denna är för vänster TerrainCheck.
"""
func _on_TerrainArea2_body_exited(body):
	if body.is_in_group("Tile"):
		if state == IDLE:
			turn = true
		elif state == CHASE:
			wait = true
	can_check_left = false


"""
Denna funktion anropas då wraithen tar skada. Wraithens hp minskar och healthbaren
uppdateras. Om den inte var synlig tidigare så blir den det nu.
Om hp är mindre eller lika med 0 så övergår state till DIE. OM den inte dör så
spelas ljudeffekter som visar att den tar skada.
"""
func take_damage(damage) -> void:
	hp -= damage * (2 - difficulty)
	$HealthBar.value = hp
	if hp < 100:
		$HealthBar.visible = true
	else:
		$HealthBar.visible = false
	if hp <= 0:
		state = DIE
	else:
		$Death.volume_db = -3
		$Death.pitch_scale = 1.5
		$Death.play()
		

"""
Om spelaren kommer in i TopKillArean så betyder det att spelaren har hoppat på
wratihens huvud, och den ska nu dö. Spelaren kommer då att bli knockad upp i
luften, då take_damage()-funktionen anropas men damage är 0. Wraithen går in i
state DIE.
"""
func _on_TopKillArea_body_entered(body: Node) -> void:
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
	#då spelaren rör sig tillräckligt högt upp och rör sig nedåt så är topkill enabled.
	#annars är den disabled för att annars dör wraithen då spelaren krockar in i den från sidan
	if global_position.y - player.global_position.y >= 48 and Globals.y_move != -1:
		$TopKill.set_collision_layer_bit(10, true)
		$TopKill/CollisionShape2D.disabled = false
		$TopKill/TopKillArea/CollisionShape2D.disabled = false
	else:
		$TopKill.set_collision_layer_bit(10, false)
		$TopKill/CollisionShape2D.disabled = true
		$TopKill/TopKillArea/CollisionShape2D.disabled = true
	#om spelaren inte ska kunna kollidera med wraiths så stänger wraithen av sina collisionshapes.
	if not Globals.can_collide:
		$KinematicBody2D/PlayerCollision.disabled = true
		$WraithArea/CollisionShape2D.disabled = true
	else:
		$KinematicBody2D/PlayerCollision.disabled = false
		$WraithArea/CollisionShape2D.disabled = false
	#Då spelaren rör sig uppåt så är denna SHape disabled för att spelaren ska
	#kunna hoppa upp genom wraithen och inte fastna under.
	if Globals.y_move == -1:
		$KinematicBody2D/PlayerCollision.disabled = true


"""
Då denna timer stannar så är knockback över, och wraithen fortsätter som den
gjorde innan.
"""
func _on_KnockBackTimer_timeout():
	knockback = false


"""
Om spelaren går ur WraithArean så blir TopKill enabled igen.
"""
func _on_WraithArea_body_exited(body):
	if body.is_in_group("Player"):
		$TopKill/CollisionShape2D.set_deferred("disabled", false)
		$TopKill/TopKillArea/CollisionShape2D.set_deferred("disabled", false)
