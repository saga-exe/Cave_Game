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

var state = IDLE

var can_jump = true

onready var sprite = $AnimatedSprite


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
	elif Input.is_action_just_pressed("move_left"):
		last_action_pressed = "left"
	sprite.flip_h = last_action_pressed != "right"
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
	else:
		sprite.play("Idle")
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





