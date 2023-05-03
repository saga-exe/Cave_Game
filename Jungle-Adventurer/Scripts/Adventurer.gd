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

enum {IDLE, RUN, AIR, CLIMB, FINISHED}

const ACCELERATION = 1700
const JUMP_STRENGTH = -450


var GRAVITY = 1000
var MAX_SPEED = 100
var direction_x = "RIGHT"
var velocity := Vector2.ZERO
var direction := Vector2.ZERO
var run = false
var last_action_pressed = "right"
var input_x = 0
var hp = 100
var knockback_direction_player = 0
var difficulty = 0
var last_pos = Vector2(190, 485)

var frame = 0
var frame_number = 1

var bullet_direction = Vector2.ZERO

var state = IDLE

var can_jump := true
var can_shoot := true
var is_shooting := false
var knockback := false
var ladder_area := false
var climb_area := false
var stopper_area := false
var shot := false
var can_end := false
var can_double_jump := false
var speed_power := false
var can_extra_attack := true
var drop_area := false
var right_played := false
var left_played := false

var playerfire_scene = preload("res://Scenes/PlayerFire.tscn")
var playerfireextra_scene = preload("res://Scenes/PlayerFireExtra.tscn")

onready var sprite = $AnimatedSprite
onready var gunpoint = $GunPoint
onready var player_area = $PlayerArea
onready var HUD = get_node("/root/MainScene/HUD")
onready var anim_player = get_node("/root/MainScene/AnimationPlayer")
onready var background_music = get_node("/root/MainScene/BackgroundMusic")
onready var background_music_fade = get_node("/root/MainScene/SoundPlayer")


"""

"""
func _ready() -> void:
	background_music.playing = true
	background_music_fade.play("MusicFadeIn")
	$Camera2D.limit_right = Globals.camera_limit
	if Globals.power != "none":
		power_up(Globals.power)
	global_position = Vector2(Globals.start_pos)
	$Effects.play("Idle")
	difficulty = Globals.difficulty
	Globals.damaged = false
	Globals.can_collide = true
	last_pos = Globals.start_pos


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


func _sprite_left() -> void:
	sprite.set_flip_h(true)
	sprite.position.x = -21
	gunpoint.position.x = -30


func _sprite_right() -> void:
	sprite.set_flip_h(false)
	sprite.position.x = 19
	gunpoint.position.x = 30


func _idle_state(delta) -> void:
	direction.x = _get_input_x_update_direction()
	_left_right_movement(delta)
	_climb()
	
	if (Input.is_action_just_pressed("shoot") and can_shoot) or (not can_shoot and (can_extra_attack or $ExtraAttackTimer.time_left != 0)):
		_attack()
	elif $ExtraAttackTimer.time_left <= 0 and ((Input.is_action_just_pressed("extra_attack") and can_shoot and can_extra_attack) or (not can_extra_attack)):
		_extra_attack()
	else:
		sprite.play("Idle")
	
	if Input.is_action_just_pressed("down") and drop_area:
		set_collision_mask_bit(2, false)
		_airstate_switch()
		return
	
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


func _run_state(delta) -> void:
	direction.x = _get_input_x_update_direction()
	_left_right_movement(delta)
	_climb()
	
	_walking_sounds($AnimatedSprite.frame)
	
	if (Input.is_action_just_pressed("shoot") and can_shoot) or (not can_shoot and (can_extra_attack or $ExtraAttackTimer.time_left != 0)):
		_attack()
	elif $ExtraAttackTimer.time_left <= 0 and ((Input.is_action_just_pressed("extra_attack") and can_shoot and can_extra_attack) or (not can_extra_attack)):
		_extra_attack()
	else:
		if Input.is_action_pressed("sprint"):
			sprite.play("Run")
		else:
			sprite.play("Walk")
	
	if Input.is_action_just_pressed("down") and drop_area:
		set_collision_mask_bit(2, false)
		_airstate_switch()
		return
	
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
	
	


func _air_state(delta) -> void:
	#set_collision_mask_bit(2, true)
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
	
	


func _climb_state(delta) -> void:
	can_jump = false
	if velocity == Vector2(0,0):
		sprite.stop()
	else:
		sprite.play("Climb")
	var CLIMB_SPEED = 150
	set_collision_mask_bit(2, false)
	direction.x = _get_input_x_update_direction()
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


func _bullet_direction() -> float:
	# bullet_target is the position the bullet is aiming for
	# bullet_target.x is always aimed to the correct side, and is later corrected if running
	var bullet_target = Vector2.ZERO
	var angle = 0
	if state == IDLE:
		if gunpoint.global_position.x - get_global_mouse_position().x <= 0:
			last_action_pressed = "right"
			gunpoint.position = Vector2(30, 0)
			
		else:
			last_action_pressed = "left"
			gunpoint.position = Vector2(-30, 0)

	if gunpoint.global_position.x - get_global_mouse_position().x <= 0:
		bullet_target.x =  get_global_mouse_position().x - gunpoint.global_position.x
	else:
		bullet_target.x = gunpoint.global_position.x - get_global_mouse_position().x


	angle = (get_global_mouse_position() - gunpoint.global_position).angle()
	if angle >= deg2rad(30) and angle <= deg2rad(150):
		angle = deg2rad(30)
	elif angle >= deg2rad(-150) and angle <= deg2rad(-30):
		angle = deg2rad(-30)
	elif angle <= deg2rad(180) and angle >= deg2rad(150):
		angle = deg2rad(180 - rad2deg(angle))
	elif angle <= deg2rad(-150) and angle >= deg2rad(-180):
		angle = deg2rad(-180 - rad2deg(angle))
	
	if last_action_pressed == "right":
		bullet_target.y = bullet_target.x*tan(angle)
		bullet_target += gunpoint.global_position
	else:

		bullet_target.y = -bullet_target.x*tan(angle)
		bullet_target = gunpoint.global_position - bullet_target
	
	var bullet_instance = playerfire_scene.instance()
	bullet_instance.global_position = gunpoint.global_position
	bullet_instance.set_direction(gunpoint.global_position, bullet_target)

	return bullet_instance


func _attack() -> void:
	can_shoot = false
	if not $Attack.playing:
		$Attack.play()
	
	if velocity.x != 0:
		_walking_sounds(frame)
	
	if global_position.x - get_global_mouse_position().x > 0:
		last_action_pressed = "left"
	else:
		last_action_pressed = "right"
	
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
		
	
	if sprite.get_frame() >= 4 and not shot:
		shot = true
		var bullet_instance = _bullet_direction()
		get_tree().get_root().add_child(bullet_instance)
	
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


func _extra_attack() -> void:
	HUD.mana_changed(0)
	can_shoot = false
	can_extra_attack = false
	velocity.x = 0
	sprite.play("AttackExtra")
	
	if not $ExtraAttack.playing:
		$ExtraAttack.play()
	
	if global_position.x - get_global_mouse_position().x > 0:
		last_action_pressed = "left"
	else:
		last_action_pressed = "right"
	
	if frame_number > 6:
		frame_number = 0
	else:
		frame_number += 1
		
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
	
	if sprite.get_frame() >= 6 and frame_number >= 5:
		can_shoot = true
		shot = false
		frame = 0
		frame_number = 1
		$ExtraAttackTimer.start()


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
		


func _on_PlayerArea_body_entered(body):
	if body.is_in_group("Ladders"):
		ladder_area = true
	elif body.is_in_group("End"):
		can_end = true
	elif body.is_in_group("Lava"):
		velocity.y = -250
		velocity.x = 0
		if not Globals.damaged:
			take_damage(25, 0)
		$PlayerArea.set_collision_mask_bit(6, false)
		state = FINISHED
	elif body.is_in_group("ClimbArea"):
		climb_area = true
	elif body.is_in_group("DropArea"):
		drop_area = true
	elif body.is_in_group("ClimbStopper"):
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
		

func _on_PlayerArea_body_exited(body):
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
	elif body.is_in_group("ClimbStopper"):
		stopper_area = false
	elif body.is_in_group("End"):
		can_end = false
	elif body.is_in_group("ClimbArea"):
		climb_area = false
	elif body.is_in_group("DropArea"):
		drop_area = false
		set_collision_mask_bit(2, true)
		

func _climb() -> void:
	if ladder_area:
		can_jump = false
		if (Input.is_action_pressed("down") and not stopper_area) or Input.is_action_pressed("jump"):
			state = CLIMB
	elif climb_area:
		if Input.is_action_pressed("down"):
			state = CLIMB


func _on_DamageTimer_timeout() -> void:
	if Globals.power == "none":
		Globals.can_collide = true
	Globals.damaged = false
	set_collision_mask_bit(1, true)
	$PlayerArea.set_collision_mask_bit(1, true)
	$Effects.stop()

func _airstate_switch() -> void:
	state = AIR
	can_jump = false
	can_double_jump = true


func _runstate_switch() -> void:
	state = RUN
	can_jump = true
	can_double_jump = true


func _idlestate_switch() -> void:
	state = IDLE
	can_jump = true
	can_double_jump = true


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
		
	
func power_up(power) -> void:
	$PowerUpTimer.start()
	if power == "speed":
		speed_power = true
		Globals.power = "speed"
		$Power.pitch_scale = 1
		$Power.play()
	elif power == "star":
		speed_power = true
		Globals.power = "star"
		Globals.can_collide = false
		$Effects.play("StarPower")
		$Power.pitch_scale = 1.2
		$Power.play()


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


func heal(health):
	hp += health * (2 - difficulty)
	HUD.health_changed(hp)


func _on_ExtraAttackTimer_timeout():
	can_extra_attack = true


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
	
	if current_frame == 0 or current_frame > 5:
		right_played = false
		left_played = false
