extends KinematicBody2D

enum {IDLE, RUN, AIR}

const ACCELERATION = 1500
const GRAVITY = 1000
const JUMP_STRENGHT = -500


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

var bullet_scene = preload("res://Scenes/Bullet.tscn")

onready var sprite = $AnimatedSprite
onready var gunpoint = $GunPoint

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
			sprite.set_flip_h(false)
			if velocity.x > 0 or last_action_pressed == "left":
				knockback = false
		else:
			sprite.set_flip_h(true)
			if velocity.x < 0 or last_action_pressed == "right":
				knockback = false

	elif velocity.x != 0:
		if velocity.x < 0:
			sprite.set_flip_h(true)
		else:
			sprite.set_flip_h(false)
	else:
		if last_action_pressed == "left":
			sprite.set_flip_h(true)
		else:
			sprite.set_flip_h(false)
			

		
	
	if last_action_pressed == "left" and Input.is_action_pressed("move_left"):
		input_x = -1
	elif last_action_pressed == "right" and Input.is_action_pressed("move_right"):
		input_x = 1
	else:
		input_x = 0
	return input_x


func _idle_state(delta) -> void:
	direction.x = _get_input_x_update_direction()
	if Input.is_action_just_pressed("jump") and can_jump:
		velocity.y = JUMP_STRENGHT
		can_jump = false
		state = AIR
		sprite.play("Jump")
		return
		
	_left_right_movement(delta)
	
		
	if velocity.x != 0:
		state = RUN
		sprite.play("Run")
		return
		
	if Input.is_action_just_pressed("shoot") and can_shoot:
		_shoot()
		return


func _run_state(delta) -> void:
	direction.x = _get_input_x_update_direction()
	if Input.is_action_just_pressed("jump") and can_jump:
		velocity.y = JUMP_STRENGHT
		can_jump = false
		state = AIR
		sprite.play("Jump")
		return
	

	_left_right_movement(delta)
	
	if not is_on_floor():
		state = AIR
		can_jump = false
		sprite.play("Jump")
	
	if is_on_floor() and velocity == Vector2.ZERO:
		state = IDLE
		sprite.play("Idle")
		return
	
	if Input.is_action_just_pressed("shoot") and can_shoot:
		_shoot()
		return

func _air_state(delta) -> void:
	velocity.y = velocity.y + GRAVITY * delta if velocity.y + GRAVITY * delta < 500 else 500 
	direction.x = _get_input_x_update_direction()
	if direction.x != 0:
		velocity.x = move_toward(velocity.x, direction.x * MAX_SPEED, ACCELERATION*delta)
	else:
		velocity.x = move_toward(velocity.x, 0, ACCELERATION * delta)
	velocity = move_and_slide(velocity, Vector2.UP)
	
	if is_on_floor():
		state = IDLE
		sprite.play("Idle")
		can_jump = true
		return
	
	if Input.is_action_just_pressed("shoot") and can_shoot:
		_shoot()
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
	sprite.play("Shoot")
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
	knockback_direction_player = knockback_direction





