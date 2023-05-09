extends KinematicBody2D

"""
Layer1: Adventurer
Layer2: Enemy (slime, wraith)
Layer3: Platforms
Layer4: Spawn objects
Layer5: Coins
Layer6: EnemySpawner
Layer7: Ladders, End, Lava (PlayerArea interactions)
Layer8: ClimbStoppers
Layer9: Bullets
Layer10: Noninteractive objects (terraincheck)
Layer11: Enemy 2 (TopKill)
Layer12: Bridges
"""

enum {IDLE, RUN, AIR, CLIMB, FINISHED} #states

const ACCELERATION = 1700
const JUMP_STRENGTH = -450


var GRAVITY = 1000
var MAX_SPEED = 100
var velocity := Vector2.ZERO
var direction := Vector2.ZERO
var last_action_pressed = "right" #den senaste håll spelaren klickade på (höger/vänster)
var input_x = 0 #den håll spelkaraktären ska röra sig åt i x-led
var hp = 100
var knockback_direction_player = 0 #det håll knockback ska gå åt (höger/vänster)
var difficulty = 0 #svårighetsgrad som tas från Globals
var last_pos = Vector2(190, 485) #positionen som spelaren kommer att respawnas på ifall den trillar ned i lava

var frame = 0 #används för att skjuta eldkula på rätt frame i attackerna
var frame_number = 1 #används för att skjuta eldkula på rätt frame i attackerna

var bullet_direction = Vector2.ZERO #det håll eldkulan ska åka åt

var state = IDLE

var can_jump := true #om true så kan spelkaraktären hoppa
var can_shoot := true #om true så kan spelkaraktären skjuta
var is_shooting := false #om true så skjuter spelkaraktären
var knockback := false #om true: spelkaraktären är tillbakaknockad efter att ha krockat med en fiende
var ladder_area := false #om true: spelkaraktären är i en "ladder area" som är specifika tiles i en tilemap i level scenen. när true så är spelkaraktären på en stege, antingen klättrandes eller förbipassreande. ifall förbipasserande så kan den börja klättra.
var climb_area := false #om true: spelkaraktären är i en "climb area" som är specifika tiles i en tilemap i level scenen. när true så kan spelkaraktären börja klättra, men endast nedåt.
var stopper_area := false #om true: spelkaraktären är i en "climb area" som är specifika tiles i en tilemap i level scenen. när true så kan spelkaraktären inte klättra nedåt, utan den står nu på plattformen.
var shot := false #används för att se till så att endast en eldkula skjuts per animation. om true så kan inga fler kulor skjutas under den pågående animationen.
var can_end := false #är true när spelkaraktären är i en grottöppning vilket är slutet på leveln. när true kan spelaren trycka på E och leveln är då avklarad.
var can_double_jump := false #är true när spelkaraktären kan dubbelhoppa. blir false då spelaren har hoppat två gånger utan att landa mellan. blir sant då karaktären landar.
var speed_power := false #om true så har spelaren plockat upp en speed powerup, som gör att spelkaraktären springer snabbare. blir flasse då PowerUpTimer har slut på tid.
var can_extra_attack := true #är true när spelkaraktären kan använda sin extraattack. är flaskt om ExtraAttackTimer har tid kvar (mana är inte fullt återställd).
var right_played := false #används för att bestämma om det senaste stegljudet som spelades var av höger fot. om sant så var höger senast och då spelas vänster fots ljud nästa gång.
var left_played := false #används för att bestämma om det senaste stegljudet som spelades var av vänster fot. om sant så var vänster senast och då spelas höger fots ljud nästa gång.

var drop_area := false  #is this used?

var playerfire_scene = preload("res://Scenes/PlayerFire.tscn")  #spelarens vanliga attacks eldkula
var playerfireextra_scene = preload("res://Scenes/PlayerFireExtra.tscn") #spelarens extraattacks eld

onready var sprite = $AnimatedSprite #spelarens sprite
onready var gunpoint = $GunPoint #en punkt hos spelarkaraktären som används för att bestämma var kulan ska komma ifrån.
onready var player_area = $PlayerArea #spelarkaraktärens area
onready var HUD = get_node("/root/MainScene/HUD") #spelarens HUD
onready var anim_player = get_node("/root/MainScene/AnimationPlayer") #används för att kalla på en AnimationPlayer i MainScene som spelar övergångar.
onready var background_music = get_node("/root/MainScene/BackgroundMusic") #används för att starta/stoppa backgrundsmusiken
onready var background_music_fade = get_node("/root/MainScene/SoundPlayer") #används för att göra övergångar i musiken mindre hackiga. då denna används antingen tonar musiken in eller ut.


"""
Startfunktion som ser till att allt är återställt då en ny level börjar. backgrundsmusiken 
tonar in, spelkaraktären är inte skadad och har inga powerups.
"""
func _ready() -> void:
	background_music.playing = true
	background_music_fade.play("MusicFadeIn")
	$Camera2D.limit_right = Globals.camera_limit #ser till så att kameran inte går utanvför leveln
	if Globals.power != "none":
		power_up(Globals.power)
	global_position = Vector2(Globals.start_pos)
	$Effects.play("Idle")
	difficulty = Globals.difficulty
	Globals.damaged = false
	Globals.can_collide = true
	last_pos = Globals.start_pos


"""
Funktion som ser till att allt fungerar för spelkaraktären. Gör så att effekter spelar då de ska,
Globala variablar är uppdaterade (ifall spelaren har en powerup, är skadad och hur spelaren rör sig
i förhållande till y-axeln. Här uppdateras vilket state karaktären är i.)
"""
func _physics_process(delta: float) -> void:
	if Globals.power == "none":
		$Power.stop()
		if not Globals.damaged:
			$Effects.play("Idle")
		speed_power = false
	if not Globals.damaged and Globals.power != "star":
		$Effects.play("Idle")
	if $ExtraAttackTimer.time_left > 0:
		HUD.mana_changed(8-$ExtraAttackTimer.time_left)
	if Globals.level == 0:
		$Light2D.texture_scale = 4
	elif Globals.level != 0 and Globals.power != "star":
		$Light2D.texture_scale = 1
	if velocity.y < 0:
		Globals.y_move = -1
	elif velocity. y > 0:
		Globals.y_move = 1
	else:
		Globals.y_move = 0
	match state:
		IDLE:
			_idle_state(delta)
		RUN:
			_run_state(delta)
		AIR:
			_air_state(delta)
		CLIMB:
			_climb_state(delta)
		FINISHED:
			_finished_state(delta)


"""
bestämmer hur snabbt spelaren kan gå och springa beroende på om den sprintar eller inte och om den
har en powerup. Ser också till så att karaktären rör sig och vilken hastighet den bör ha, både i x-
och y-led.
"""
func _left_right_movement(delta) -> void:
	if Input.is_action_pressed("sprint") and not speed_power:
		MAX_SPEED = 160
	elif Input.is_action_pressed("sprint"):
		MAX_SPEED = 300
	elif speed_power:
		MAX_SPEED = 200
	else:
		MAX_SPEED = 100

	if direction.x != 0:
		velocity = velocity.move_toward(direction*MAX_SPEED, ACCELERATION*delta)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, ACCELERATION*delta)
	
	velocity.y += GRAVITY*delta
	velocity = move_and_slide(velocity, Vector2.UP)


"""
denna funktion bestämmer vilket håll spelkaraktären ska vändas (vänster/höger). den loggar också det
senaste hållet spelaren klickade på (vänster/höger). Den sätter också knockback till false då
knockback ska vara false. funktionen returnerar input_x som sedan används för att spelkaraktären ska
röra sig åt rätt håll.
"""
func _get_input_x_update_direction() -> float:
	if Input.is_action_just_pressed("move_right"):
		last_action_pressed = "right"
	elif Input.is_action_just_pressed("move_left"):
		last_action_pressed = "left"
	
	if knockback:
		if knockback_direction_player < 0:
			_sprite_right()
			if velocity.x > 0 or last_action_pressed == "left":
				knockback = false
		else:
			_sprite_left()
			if velocity.x < 0 or last_action_pressed == "right":
				knockback = false

	elif velocity.x != 0:
		if velocity.x < 0:
			_sprite_left()
		else:
			_sprite_right()
	else:
		if last_action_pressed == "left":
			_sprite_left()
		else:
			_sprite_right()
	
	if last_action_pressed == "left" and Input.is_action_pressed("move_left"):
		input_x = -1
	elif last_action_pressed == "right" and Input.is_action_pressed("move_right"):
		input_x = 1
	else:
		input_x = 0
	return input_x


"""
en hjälpfunktion som sätter alla inställningar rätt när de ska ändras till att spelkaraktären är
vänd mot vänster. den flippar spriten och sätter gunpoint på andra sidan så att den matchar sprites
när skjutanimationen spelar. spritepositionen ändras också lite för att den alltid ska vara mitt i
collisionshapen.
"""
func _sprite_left() -> void:
	sprite.set_flip_h(true)
	sprite.position.x = -21
	gunpoint.position.x = -30


"""
en hjälpfunktion som sätter alla inställningar rätt när de ska ändras till att spelkaraktären är
vänd mot höger. den flippar spriten och sätter gunpoint på andra sidan så att den matchar sprites
när skjutanimationen spelar. spritepositionen ändras också lite för att den alltid ska vara mitt i
collisionshapen.
"""
func _sprite_right() -> void:
	sprite.set_flip_h(false)
	sprite.position.x = 19
	gunpoint.position.x = 30


"""
state då spelaren står still. 

Anropar funktion för rörelse (_left_right_movement(delta)). Anropar funktion (climb()) som kollar
ifall spelaren börjar klättra. Ändrar state ifall krav för annat state uppfylls. Sätter state till
finished ifall spelaren klarat av level eller spelkaraktären faller ur bild.

Om spelaren skjuter vanlig eller extraattack och den kan skjuta så startars processen här genom
att kalla på respektive funtion. annars spelas en idle-animation
"""
func _idle_state(delta) -> void:
	_left_right_movement(delta)
	_climb()
	
	#om spelaren skjuter vanlig eller extraattack och den kan skjuta så startars processen här genom
	#att kalla på respektive funtion. annars spelas idle-animation
	if (Input.is_action_just_pressed("shoot") and can_shoot) or (not can_shoot and (can_extra_attack or $ExtraAttackTimer.time_left != 0)):
		_attack()
	elif $ExtraAttackTimer.time_left <= 0 and ((Input.is_action_just_pressed("extra_attack") and can_shoot and can_extra_attack) or (not can_extra_attack)):
		_extra_attack()
	else:
		sprite.play("Idle")
	
	if can_end and Input.is_action_just_pressed("E"):
		state = FINISHED
	
	if global_position.y > 620:
		state = FINISHED
		hp -= 25
	
	if Input.is_action_just_pressed("jump") and can_jump:
		velocity.y = JUMP_STRENGTH
		_airstate_switch()
		return
		
	elif velocity.x != 0:
		_runstate_switch()
		return


"""
state då spelaren rör på sig på marken. 

Anropar funktion för rörelse (_left_right_movement(delta)). Anropar funktion (climb()) som kollar
ifall spelaren börjar klättra. Ändrar state ifall krav för annat state uppfylls. Sätter state till
finished ifall spelaren klarat av level eller spelkaraktären faller ur bild. anropar funktion för
att ljud ska spelas eftersom karaktären rör på sig (_walking_sounds($AnimatedSprite.frame)).

Om spelaren skjuter vanlig eller extraattack och den kan skjuta så startars processen här genom
att kalla på respektive funtion. annars spelas animation beroende på om spelaren sprintar eller ej
"""
func _run_state(delta) -> void:
	_left_right_movement(delta)
	_climb()
	
	_walking_sounds($AnimatedSprite.frame)
	
	#om spelaren skjuter vanlig eller extraattack och den kan skjuta så startars processen här genom
	#att kalla på respektive funtion. annars spelas animation beroende på om spelaren sprintar eller ej
	if (Input.is_action_just_pressed("shoot") and can_shoot) or (not can_shoot and (can_extra_attack or $ExtraAttackTimer.time_left != 0)):
		_attack()
	elif $ExtraAttackTimer.time_left <= 0 and ((Input.is_action_just_pressed("extra_attack") and can_shoot and can_extra_attack) or (not can_extra_attack)):
		_extra_attack()
	else:
		if Input.is_action_pressed("sprint"):
			sprite.play("Run")
		else:
			sprite.play("Walk")
	
	if can_end and Input.is_action_just_pressed("E"):
		state = FINISHED
	
	if global_position.y > 620:
		state = FINISHED
		hp -= 25
	
	if Input.is_action_just_pressed("jump") and can_jump:
		velocity.y = JUMP_STRENGTH
		_airstate_switch()
		return
	
	if not is_on_floor():
		_airstate_switch()
		return
	
	if is_on_floor() and velocity == Vector2.ZERO:
		_idlestate_switch()
		return


"""
state då spelaren är i luften. 

_air_state() har kod för rörelse i luft samt hur snabb spelkaraktären är. Denna funktion ser också
till så att double jump fungerar.

Anropar funktion (climb()) som kollar ifall spelaren börjar klättra. Ändrar state ifall krav för
annat state uppfylls. Sätter state till finished ifall spelaren klarat av level eller spelkaraktären
faller ur bild. Anropar funktion för att ljud ska spelas eftersom karaktären rör på sig
(_walking_sounds($AnimatedSprite.frame)).

Om spelaren skjuter vanlig eller extraattack och den kan skjuta så startars processen här genom
att kalla på respektive funtion. annars spelas en jump-animation
"""
func _air_state(delta) -> void:
	velocity.y = velocity.y + GRAVITY * delta if velocity.y + GRAVITY * delta < 500 else 500 
	direction.x = _get_input_x_update_direction()
	if direction.x != 0:
		velocity.x = move_toward(velocity.x, direction.x * MAX_SPEED, ACCELERATION*delta)
	else:
		velocity.x = move_toward(velocity.x, 0, ACCELERATION * delta)
	velocity = move_and_slide(velocity, Vector2.UP)
	
	if can_end and Input.is_action_just_pressed("E"):
		state = FINISHED
	
	if global_position.y > 620:
		state = FINISHED
		hp -= 25
	
	if Input.is_action_just_pressed("jump") and can_double_jump:
		can_double_jump = false
		velocity.y = -300
		if can_shoot:
			sprite.play("DoubleJump")
	
	#om spelaren skjuter vanlig eller extraattack och den kan skjuta så startars processen här genom
	#att kalla på respektive funtion. annars spelas en jump-animation
	if (Input.is_action_just_pressed("shoot") and can_shoot) or (not can_shoot and (can_extra_attack or $ExtraAttackTimer.time_left != 0)):
		_attack()
	elif $ExtraAttackTimer.time_left <= 0 and ((Input.is_action_just_pressed("extra_attack") and can_shoot and can_extra_attack) or (not can_extra_attack)):
		_extra_attack()
	elif can_double_jump:
		sprite.play("Jump")
	elif can_shoot:
		sprite.play("DoubleJump")
	
	if Input.is_action_pressed("sprint") and not speed_power:
		MAX_SPEED = 160
	elif Input.is_action_pressed("sprint"):
		MAX_SPEED = 300
	elif speed_power:
		MAX_SPEED = 200
	else:
		MAX_SPEED = 100
	
	_climb()
	
	if is_on_floor():
		_idlestate_switch()
		return


"""
state för när spelkaraktären klättrar på en stege.

Sätter state till finished ifall spelaren klarat av level eller spelkaraktären faller ur bild.

när karaktären klättrar, så kan den inte kollidera med plattformar så att den kan klättra ner genom
dem, vilket är varför det finns "climb stoppers". de går inte att klättra igenom och finns under
stegar för att stoppa spelaren från att klättra för långt.

Ifall spelaren rör på sig i climb_state() så spelas den klättrande animationen, annars står
animationen still.

climb_state() använder sina egna fysiklagar, då gravitationen är "avstängd" för att kunna klättra
upp och ner.

Då spelaren inte längre är i ladder_area eller climb_area så byts state till det som matchar.
"""
func _climb_state(delta) -> void:
	can_jump = false
	var CLIMB_SPEED = 150
	set_collision_mask_bit(2, false)
	
	if velocity == Vector2(0,0):
		sprite.stop()
	else:
		sprite.play("Climb")
	
	if Input.is_action_pressed("down"):
		direction.y = 1
	elif Input.is_action_pressed("jump"):
		direction.y = -1
	else:
		direction.y = 0

	velocity = velocity.move_toward(direction*CLIMB_SPEED, ACCELERATION*delta)
	velocity = move_and_slide(velocity, Vector2.UP)
	
	if can_end and Input.is_action_just_pressed("E"):
		state = FINISHED
	
	if global_position.y > 620:
		state = FINISHED
		hp -= 25
	
	if not ladder_area and climb_area:
		if Input.is_action_pressed("down"):
			return
		else:
			direction.y = 0
			set_collision_mask_bit(2, true)
			if is_on_floor() and velocity != Vector2.ZERO:
				_runstate_switch()
				return
			elif is_on_floor():
				_idlestate_switch()
				return
			elif not is_on_floor():
				_airstate_switch()
				return


"""
Denna funktion är till för att eldkulan i spelkaraktärens vanliga attack ska riktas åt rätt håll.
 – bullet_target är positionen eldkulan ska skjutas mot
 – bullet_target.x är riktad åt det håll musen är i förhållande till spelaren, men om state är RUN
   så byts bullet_target.x om det inte är samma som det håll spelkaraktären springer åt
"""
func _bullet_direction() -> float:
	var bullet_target = Vector2.ZERO
	var angle = 0
	
	#ifall spelaren står still så byter spelkaraktären håll baserat på vilket håll spelaren skjuter åt,
	#men om spelaren inte står still så skjuter den åt det håll spelkaraktären rör sig åt.
	if state == IDLE:
		if gunpoint.global_position.x - get_global_mouse_position().x <= 0:
			last_action_pressed = "right"
			gunpoint.position = Vector2(30, 0)
		else:
			last_action_pressed = "left"
			gunpoint.position = Vector2(-30, 0)

	#räknar ut åt vilket håll kulan ska skjutas åt
	if gunpoint.global_position.x - get_global_mouse_position().x <= 0:
		bullet_target.x =  get_global_mouse_position().x - gunpoint.global_position.x
	else:
		bullet_target.x = gunpoint.global_position.x - get_global_mouse_position().x

	
	#kulan kan endast åka i ett intervall på 60° åt höger och vänster för att göra spelet svårare
	angle = (get_global_mouse_position() - gunpoint.global_position).angle()
	if angle >= deg2rad(30) and angle <= deg2rad(150):
		angle = deg2rad(30)
	elif angle >= deg2rad(-150) and angle <= deg2rad(-30):
		angle = deg2rad(-30)
	elif angle <= deg2rad(180) and angle >= deg2rad(150):
		angle = deg2rad(180 - rad2deg(angle))
	elif angle <= deg2rad(-150) and angle >= deg2rad(-180):
		angle = deg2rad(-180 - rad2deg(angle))
	
	#här sätts bullet_target ihop för att användas till bullet_instance
	if last_action_pressed == "right":
		bullet_target.y = bullet_target.x*tan(angle)
		bullet_target += gunpoint.global_position
	else:
		bullet_target.y = -bullet_target.x*tan(angle)
		bullet_target = gunpoint.global_position - bullet_target
	
	#här sätts bullet_instance ihop för att skickas vidare till _attack() - funktionen
	var bullet_instance = playerfire_scene.instance()
	bullet_instance.global_position = gunpoint.global_position
	bullet_instance.set_direction(gunpoint.global_position, bullet_target)

	return bullet_instance


"""
Denna funktion står för den vanliga attacken.
"""
func _attack() -> void:
	can_shoot = false
	if not $Attack.playing:
		$Attack.play()
	
	#anropar funktion som spelar upp gåljud 
	if velocity.x != 0:
		_walking_sounds(frame)
	
	#last_action_pressed är nu baserat på var musen är i förhållande till spelkaraktären för att
	#vända karaktären till det håll den skjuter
	if global_position.x - get_global_mouse_position().x > 0:
		last_action_pressed = "left"
	else:
		last_action_pressed = "right"
	
	"""
	här används variabler frame och frame_number för att kunna skjuta eldkulan vid rätt tillfälle i
	animationen. frame är vilken frame i animationen som spelas, medan frame_number är hur många
	gånger funktionen ska köras innan nästa frame i animationen ska spelas. frame_number varierar
	beroende på vilken animation som spelas (idle, walk, run)
	"""
	if velocity.x == 0:
		sprite.play("Attack")
		if frame_number <= 6:
			sprite.set_frame(frame)
		else:
			frame_number = 0
			frame += 1
			sprite.set_frame(frame)
		frame_number += 1
	elif Input.is_action_pressed("sprint"):
		sprite.play("RunAttack")
		if frame_number <= 4:
			sprite.set_frame(frame)
		else:
			frame_number = 0
			frame += 1
			sprite.set_frame(frame)
		frame_number += 1
	else:
		sprite.play("WalkAttack")
		if frame_number <= 6:
			sprite.set_frame(frame)
		else:
			frame_number = 0
			frame += 1
			sprite.set_frame(frame)
		frame_number += 1
		
	#när rätt frame spelas så skjuter karaktären iväg en eldkula, men eftersom funktionen gås igenom
	#flera gånger under samma frame så används "shot" för att se till så att endast en kula avfyras.
	if sprite.get_frame() >= 4 and not shot:
		shot = true
		var bullet_instance = _bullet_direction()
		get_tree().get_root().add_child(bullet_instance)
	
	#då animationen är slut så återställs allt som använts under _attack() - funktionen
	if velocity.x == 0:
		if frame >= 6 and frame_number >= 6:
			can_shoot = true
			shot = false
			frame = 0
			frame_number = 1
			$Attack.stop()
	elif Input.is_action_pressed("sprint"):
		if frame >= 7 and frame_number >= 4:
			can_shoot = true
			shot = false
			frame = 0
			frame_number = 1
			$Attack.stop()
	else:
		if frame >= 6 and frame_number >= 6:
			can_shoot = true
			shot = false
			frame = 0
			frame_number = 1
			$Attack.stop()


"""
Denna funktion anropas då spelkaraktären ska utföra extraattacken.

Extraattacken åker enbart rakt till sidan, vilket betyder att den har en egen uträkning för vart den
ska åka (inte samma som den vanliga attacken).
"""
func _extra_attack() -> void:
	#all mana används upp då extraattacken används, och då börjar den "återhämtas"
	HUD.mana_changed(0)
	can_shoot = false
	can_extra_attack = false
	velocity.x = 0 #spelkaraktären står still då den använder extraattacken
	sprite.play("AttackExtra") #animationen för extraattacken spelas
	
	#spelar upp ljudet för attacken
	if not $ExtraAttack.playing:
		$ExtraAttack.play()
	
	#last_action_pressed är nu baserat på var musen är i förhållande till spelkaraktären för att
	#vända karaktären till det håll den skjuter
	if global_position.x - get_global_mouse_position().x > 0:
		last_action_pressed = "left"
	else:
		last_action_pressed = "right"
	
	"""
	frame_number för att kunna skjuta eldkulan vid rätt tillfälle i
	animationen. frame är vilken frame i animationen som spelas, medan frame_number är hur många
	gånger funktionen ska köras innan nästa frame i animationen ska spelas. frame_number varierar
	beroende på vilken animation som spelas (idle, walk, run)
	"""
	if frame_number > 6:
		frame_number = 0
	else:
		frame_number += 1
	
	#när rätt frame spelas så skjuter karaktären iväg en eldkula, men eftersom funktionen gås igenom
	#flera gånger under samma frame så används "shot" för att se till så att endast en kula avfyras.
	if sprite.get_frame() >= 5 and not shot:
		shot = true
		var bullet_instance = playerfireextra_scene.instance()
		
		if last_action_pressed == "left":
			var bullet_start = Vector2(gunpoint.global_position.x, gunpoint.global_position.y)
			var bullet_target = Vector2(gunpoint.global_position.x, gunpoint.global_position.y)
			bullet_instance.global_position = bullet_start
			bullet_target.x -= 10
			bullet_instance.set_direction(bullet_start, bullet_target)
		else:
			var bullet_start = Vector2(gunpoint.global_position.x, gunpoint.global_position.y - 15)
			var bullet_target = Vector2(gunpoint.global_position.x, gunpoint.global_position.y - 15)
			bullet_instance.global_position = bullet_start
			bullet_target.x += 10
			bullet_instance.set_direction(bullet_start, bullet_target)
		get_tree().get_root().add_child(bullet_instance)
	
	#då animationen har spelat klart återställs allt för att kunna attackera igen
	if sprite.get_frame() >= 6 and frame_number >= 5:
		can_shoot = true
		shot = false
		frame = 0
		frame_number = 1
		$ExtraAttackTimer.start()


"""
take_damage() är en funktion som anropas från fiendernas script eller då spelaren trillar ner i lava.
den används både då spelaren går in i en fiende och tar damage, men även då spelaren dödar en fiende
genom att hoppa på den. Då anropas funktionen med damage = 0, vilket ger en form av "knockback" men 
uppåt, och state byter till AIR.

Ifall spelaren tar damage så spelas ljudeffekt samt en damage-effekt på spelaren. Spelkaraktären kan
heller inte ta skada igen eller kollidera med fiender då denna effekt spelas. Det tar slut då
DamageTimer stoppar. Det ger också knockback samt gör hp lägre och ändrar det i HUDen. Om spelaren
efter det har hp <= 0 så blir det game over.
"""
func take_damage(damage, knockback_direction) -> void:
	if damage == 0:
		velocity.y = -350
		_airstate_switch()
		state = AIR
	else:
		$DamageSound.play()
		Globals.damaged = true
		Globals.can_collide = false
		$DamageTimer.start()
		velocity.x = knockback_direction * 350
		hp -= damage * difficulty
		$Effects.play("Damaged")
		if knockback_direction != 0:
			knockback = true
		HUD.health_changed(hp)
	knockback_direction_player = knockback_direction
	if hp <= 0:
		state = FINISHED


"""
Denna funktion håller koll på vad som entrar PlayerArea.
"""
func _on_PlayerArea_body_entered(body):
	if body.is_in_group("Ladders"): #om spelaren är på en stege och klättrar eller kan börja klättra
		ladder_area = true
	elif body.is_in_group("End"): #om spelaren är i arean av en grottöppning och kan avsluta leveln
		can_end = true
	elif body.is_in_group("Lava"): #om spelaren trillar ned i lavan och ska ta damage samt ladda om från checkpoint eller game over
		velocity.y = -250 #"knockback" uppåt ("studsar på lavan")
		velocity.x = 0 #spelaren kan inte fortsätta springa efter att ha trillat ned i lavan
		if not Globals.damaged:
			take_damage(25, 0)
		$PlayerArea.set_collision_mask_bit(6, false) #för att spelaren ska trilla ned genom lavan och inte ta damage igen
		state = FINISHED
	elif body.is_in_group("ClimbArea"): #om spelaren är i en climb area och kan börja klätra nedåt
		climb_area = true
	elif body.is_in_group("ClimbStopper"): #om spelaren kommer ned i en climb stopper så avslutas climb_state och den byter till det state som uppfyller kraven
		stopper_area = true
		if not is_on_floor():
			_airstate_switch()
			return
		if is_on_floor() and velocity != Vector2.ZERO:
			_runstate_switch()
			return
		elif is_on_floor():
			_idlestate_switch()
			return
		

"""
Denna funktion håller koll på vad som går ur PlayerArea.
"""
func _on_PlayerArea_body_exited(body):
	"""
	då spelaren går bort från en stege så ändras state från climb_state. om spelaren inte klättrar
	så "ändras" state till det state som spelkaraktären redan är i.
	
	"""
	if body.is_in_group("Ladders"): 
		ladder_area = false
		if not climb_area or (climb_area and not Input.is_action_pressed("down")):
			set_collision_mask_bit(2, true)
			direction.y = 0
			if not is_on_floor():
				_airstate_switch()
				return
			elif is_on_floor() and velocity != Vector2.ZERO:
				_runstate_switch()
				return
			elif is_on_floor():
				_idlestate_switch()
				return
	elif body.is_in_group("ClimbStopper"): #då spelaren inte längre är i en climbstopper
		stopper_area = false
	elif body.is_in_group("End"): #då spelaren går iväg från grottöppningnen och inte längre kan avsluta leveln
		can_end = false
	elif body.is_in_group("ClimbArea"): #då spelaren lämnar en climbarea
		climb_area = false


"""
Detta är en övergångsfunktion som avgör om spelaren börjar klättra och ändrar då state till CLIMB.
"""
func _climb() -> void:
	if ladder_area:
		can_jump = false
		if (Input.is_action_pressed("down") and not stopper_area) or Input.is_action_pressed("jump"):
			state = CLIMB
	elif climb_area:
		if Input.is_action_pressed("down"):
			state = CLIMB


"""
Då spelaren tar skada slutar den kolldiera med fiender och kan inte ta skada. Det spelas även en
effekt på spelaren. Då DamageTimer tar slut så kan spelaren kollidera (om den inte har en Star
PowerUp), ta skada och effekten slutar spela.
"""
func _on_DamageTimer_timeout() -> void:
	if Globals.power != "star":
		Globals.can_collide = true
	Globals.damaged = false
	set_collision_mask_bit(1, true)
	$PlayerArea.set_collision_mask_bit(1, true)
	$Effects.stop()



"""
En hjälpfunktion som kallas då state ska bytas till AIR. Den sätter jump till false och double jump
till true.
"""
func _airstate_switch() -> void:
	state = AIR
	can_jump = false
	can_double_jump = true


"""
En hjälpfunktion som kallas då state ska bytas till AIR. Den sätter jumpoch double jump
till true då spelaren kan både hoppa och dubbelhoppa då den befinner sig på marken.
"""
func _runstate_switch() -> void:
	state = RUN
	can_jump = true
	can_double_jump = true


"""
En hjälpfunktion som kallas då state ska bytas till AIR. Den sätter jump och double jump
till true då spelaren kan både hoppa och dubbelhoppa då den befinner sig på marken.
"""
func _idlestate_switch() -> void:
	state = IDLE
	can_jump = true
	can_double_jump = true


"""
Denna funktion kallas på då state == FINISHED. state blir finished då leveln avslutas, spelaren
trillar ned i lava, eller då hp <= 0 och det blir game over.

Om can_end == true så betyder det att leveln har avslutats och highscore sparas varefter spelet
övergår till scenen LevelFinished.

Om hp eller score blir mindre eller lika med noll så är det game over scenen som kallas på.

Annars så har spelaren trillat ned i lava och den respawnar vid det senaste tagna checkpoint.
Spelaren blir då av med eventuella powerups.
"""
func _finished_state(delta) -> void:
	velocity.y += GRAVITY*delta
	velocity.x = 0
	velocity = move_and_slide(velocity, Vector2.UP)
	sprite.play("Idle")

	if can_end:
		if Globals.level != 0:
			HUD.save_highscore()
		background_music_fade.play_backwards("MusicFadeIn")
		Transition.load_scene("res://Scenes/LevelFinished.tscn")
		$PowerUpTimer.stop()
	elif hp <= 0 or Globals.score <= 0:
		background_music_fade.play_backwards("MusicFadeIn")
		$PowerUpTimer.stop()
		Transition.load_scene("res://Scenes/GameOver.tscn")
	else:
		anim_player.play("BlackOut")
		yield(anim_player, "animation_finished")
		$PowerUpTimer.stop()
		global_position = last_pos
		_on_PowerUpTimer_timeout()
		HUD.health_changed(hp)
		anim_player.play_backwards("BlackOut")
		
		$PlayerArea.set_collision_mask_bit(6, true)
		state = IDLE
		return


"""
Då spelaren plockar upp en powerup så anropas denna funktion. Den startar PowerUpTimer och startar
musiken för powerups. Beroende på vilken powerup som plockats upp så spelas musiken lite olika
snabbt, och den globala variabeln power ändras. Om det är en stjärna som plockats upp så kan spelaren
inte kollidera och ta damage av fiender.
"""
func power_up(power) -> void:
	$PowerUpTimer.start()
	speed_power = true
	$Power.play()
	if power == "speed":
		Globals.power = "speed"
		$Power.pitch_scale = 1
	elif power == "star":
		Globals.power = "star"
		Globals.can_collide = false
		$Effects.play("StarPower")
		$Power.pitch_scale = 1.2


"""
Då PowerUpTimern tar slut så tar powerupen slut. Spelaren kan kolldiera med fiender och alla
speciella effekter slutar spela.
"""
func _on_PowerUpTimer_timeout() -> void:
	if not Globals.damaged:
		$Effects.play("Idle")
	speed_power = false
	difficulty = Globals.difficulty
	$PlayerArea.set_collision_mask_bit(1, true)
	set_collision_mask_bit(1, true)
	Globals.can_collide = true
	Globals.power = "none"
	$Power.stop()


"""
Denna funktion anropas då spelaren tar upp ett hjärta och hp ökar.
"""
func heal(health):
	hp += health * (2 - difficulty)
	HUD.health_changed(hp)


"""
Då denna timer slutat så mana har återhämtat sig och spelaren kan använda sig ev extraattacken igen.
"""
func _on_ExtraAttackTimer_timeout():
	can_extra_attack = true


"""
Denna funktion anropas av de states där spelkaraktären går på marken. Den ändrar ljudet lite
beroende på om spelaren sprintar eller går.

Funktionen spelar upp ljudet för varje fotsteg individuellt för att enkelt kunna bestämma då ljudet
ska spelas upp. Beronde på om spelaren sprintar eller inte så spelas ljuden upp på olika frames,
då spelkaraktären inte sätter ned foten på samma frame i de olika animtaionerna.
"""
func _walking_sounds(current_frame):
	if Input.is_action_pressed("sprint"):
		$Right.pitch_scale = 1.6
		$Left.pitch_scale = 1.6
	else:
		sprite.play("Walk")
		$Right.pitch_scale = 1.3
		$Left.pitch_scale = 1.3
	
	if Input.is_action_pressed("sprint"):
		if current_frame == 1 and not right_played:
			$Right.play()
			right_played = true
		elif current_frame == 5 and not left_played:
			$Left.play()
			left_played = true
	else:
		if current_frame == 2 and not right_played:
			$Right.play()
			right_played = true
		elif current_frame == 5 and not left_played:
			$Left.play()
			left_played = true
	
	if current_frame == 0 or current_frame > 5: #dessa återställs efter varje loop av animationen då karaktären endast sätter ned foten en gång per loop.
		right_played = false
		left_played = false
