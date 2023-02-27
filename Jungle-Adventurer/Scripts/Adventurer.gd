extends KinematicBody2D

#take damage when jumping up into slime
	#have several collision shapes with on way collision so can jump through and bonk and stuff?
#take damage and respawn when drop out of frame
#HUD
#game over screen
#main menu
#storyline
#nice sprites
#should i be able to sprint when already in the air?

#have sprite not continue playing when in air
#coins not spawn diagonally to the upper left of another
#stop being in climbstate when colliding with climbstopper

#stopper on bottom
#deactivate collsision with tiles
#ladder_area and jump area on top with different tilemap

"""
Layer1: Adventurer
Layer2: Slime
Layer3: Platforms
Layer4: Slimespawns
Layer5: Coins
Layer6: EnemySpawner
Layer7: Ladders
Layer8: ClimbStoppers
"""

enum {IDLE, RUN, AIR, CLIMB}

signal game_over

const ACCELERATION = 1700
const JUMP_STRENGTH = -600


var GRAVITY = 1000
var MAX_SPEED = 300
var direction_x = "RIGHT"
var velocity := Vector2.ZERO
var direction := Vector2.ZERO
var sprint = false
var last_action_pressed = "right"
var input_x = 0
var hp = 100
var knockback_direction_player = 0

var bullet_direction = Vector2.ZERO

var state = IDLE

var can_jump := true
var can_shoot := true
var is_shooting := false
var knockback := false
var ladder_area := false
var climb_area := false

var bullet_scene = preload("res://Scenes/Bullet.tscn")

onready var sprite = $AnimatedSprite
onready var gunpoint = $GunPoint
onready var player_area = $PlayerArea
onready var level = get_node("/root/MainScene/Level1/Platforms")
onready var slime = get_node("/root/MainScene/sloime")
onready var HUD = get_node("/root/MainScene/HUD")

func _ready() -> void:
	global_position = Vector2(200,400)


func _physics_process(delta: float) -> void:
	match state:
		IDLE:
			_idle_state(delta)
		RUN:
			_run_state(delta)
		AIR:
			_air_state(delta)
		CLIMB:
			_climb_state(delta)



func _left_right_movement(delta) -> void:
	if Input.is_action_pressed("sprint"):
		MAX_SPEED = 500
	else:
		MAX_SPEED = 300

	if direction.x != 0:
		velocity = velocity.move_toward(direction*MAX_SPEED, ACCELERATION*delta)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, ACCELERATION*delta)
	
	velocity.y += GRAVITY*delta
	velocity = move_and_slide(velocity, Vector2.UP)


func _get_input_x_update_direction() -> float:
	if Input.is_action_just_pressed("move_right"):
		last_action_pressed = "right"
		gunpoint.position = Vector2(210, 5)
	elif Input.is_action_just_pressed("move_left"):
		last_action_pressed = "left"
		gunpoint.position = Vector2(-190, 5)
	
	#knockback_direction = -1 => velocity.x < 0 => flip(false)
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
	sprite.position.x = -40

func _sprite_right() -> void:
	sprite.set_flip_h(false)
	sprite.position.x = 0


func _idle_state(delta) -> void:
	direction.x = _get_input_x_update_direction()
	_left_right_movement(delta)
	_climb()
	
	if Input.is_action_just_pressed("jump") and can_jump:
		velocity.y = JUMP_STRENGTH
		can_jump = false
		state = AIR
		sprite.play("Jump")
		return
		
	elif velocity.x != 0:
		state = RUN
		sprite.play("Run")
		return
		
	if Input.is_action_just_pressed("shoot") and can_shoot:
		_shoot()
		return


func _run_state(delta) -> void:
	direction.x = _get_input_x_update_direction()
	_left_right_movement(delta)
	_climb()
	if Input.is_action_just_pressed("jump") and can_jump:
		velocity.y = JUMP_STRENGTH
		can_jump = false
		state = AIR
		sprite.play("Jump")
		return
	
	if not is_on_floor():
		can_jump = false
		state = AIR
		sprite.play("Jump")
		return
	
	if is_on_floor() and velocity == Vector2.ZERO:
		state = IDLE
		sprite.play("Idle")
		return
	
	if Input.is_action_just_pressed("shoot") and can_shoot:
		_shoot()
		return

#nollställ direction.y !!!

func _air_state(delta) -> void:
	velocity.y = velocity.y + GRAVITY * delta if velocity.y + GRAVITY * delta < 500 else 500 
	direction.x = _get_input_x_update_direction()
	if direction.x != 0:
		velocity.x = move_toward(velocity.x, direction.x * MAX_SPEED, ACCELERATION*delta)
	else:
		velocity.x = move_toward(velocity.x, 0, ACCELERATION * delta)
	velocity = move_and_slide(velocity, Vector2.UP)
	
	if Input.is_action_pressed("sprint"):
		MAX_SPEED = 500
	else:
		MAX_SPEED = 300
	# ska denna del av funktion åka till slime script istället? då funkar även när slime är död
	#if velocity.y < 0 and $AntiCollisionTimer.time_left <= 0 and global_position < slime.global_position:
		#set_collision_mask_bit(1, false)
		#slime.set_collision_mask_bit(0, false)
		#$AntiCollisionTimer.start()
	
	_climb()
	
	if is_on_floor(): #and velocity == Vector2.ZERO:
		state = IDLE
		sprite.play("Idle")
		can_jump = true
		return
	#elif is_on_floor() and velocity.x != 0:
		#state = RUN
		#sprite.play("Run")
		#can_jump = true
		#return
	
	if Input.is_action_just_pressed("shoot") and can_shoot:
		_shoot()
		return


func _climb_state(delta) -> void:
	can_jump = false
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
	
	if not ladder_area and climb_area:
		if Input.is_action_pressed("down"):
			return
		else:
			direction.y = 0
			set_collision_mask_bit(2, true)
			if is_on_floor() and velocity != Vector2.ZERO:
				state = RUN
				sprite.play("Run")
				can_jump = true
				return
			elif is_on_floor():
				state = IDLE
				sprite.play("Idle")
				can_jump = true
				return
			elif not is_on_floor():
				state = AIR
				can_jump = false
				sprite.play("Jump")
				return


func _bullet_direction() -> float:
	# bullet_target is the position the bullet is aiming for
	# bullet_target.x is always aimed to the correct side, and is later corrected if running
	var bullet_target = Vector2.ZERO
	var angle = 0
	if state == IDLE:
		if gunpoint.global_position.x - get_global_mouse_position().x <= 0:
			direction.x == 1
			last_action_pressed = "right"
			gunpoint.position = Vector2(210, 5)
			
		else:
			direction.x == -1
			last_action_pressed = "left"
			gunpoint.position = Vector2(-190, 5)

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
			
	var bullet_instance = bullet_scene.instance()
	bullet_instance.global_position = gunpoint.global_position
	bullet_instance.set_direction(gunpoint.global_position, bullet_target)

	return bullet_instance




func _shoot() -> void:
	$ShootTimer.start()
	var bullet_instance = _bullet_direction()
	get_tree().get_root().add_child(bullet_instance)
	sprite.play("Attack")
	yield(sprite,"animation_finished")
	if is_on_floor() and velocity != Vector2.ZERO:
		state = RUN
		sprite.play("Run")
		can_jump = true
		return
	elif is_on_floor():
		state = IDLE
		sprite.play("Idle")
		can_jump = true
		return
	elif not is_on_floor():
		state = AIR
		can_jump = false
		sprite.play("Jump")
		return


func _on_ShootTimer_timeout() -> void:
	can_shoot = true
	return


func take_damage(damage, knockback_direction) -> void:
	if damage == 0:
		velocity.y = -350
	else:
		velocity.x = knockback_direction * 350
		hp -= damage
		knockback = true
		HUD.health_changed(hp)
	knockback_direction_player = knockback_direction
	if hp <= 0:
		emit_signal("game_over")


func _on_AntiCollisionTimer_timeout() -> void:
	set_collision_mask_bit(1, true)
	slime.set_collision_mask_bit(0, true)


func _on_PlayerArea_body_entered(body):
	if body.is_in_group("Ladders"):
		ladder_area = true
	elif body.is_in_group("ClimbArea"):
		climb_area = true

func _on_PlayerArea_body_exited(body):
	if body.is_in_group("Ladders"):
		ladder_area = false
		if not climb_area or (climb_area and not Input.is_action_pressed("down")):
			set_collision_mask_bit(2, true)
			direction.y = 0
			if not is_on_floor():
				state = AIR
				can_jump = false
				sprite.play("Jump")
				return
			if is_on_floor() and velocity != Vector2.ZERO:
				state = RUN
				sprite.play("Run")
				can_jump = true
				return
			elif is_on_floor():
				state = IDLE
				sprite.play("Idle")
				can_jump = true
				return
			
	if body.is_in_group("ClimbArea"):
		climb_area = false
		

func _climb() -> void:
	if ladder_area:
		can_jump = false
		if Input.is_action_pressed("down") or Input.is_action_pressed("jump") or state == AIR:
			state = CLIMB
	elif climb_area:
		if Input.is_action_pressed("down"):
			state = CLIMB

