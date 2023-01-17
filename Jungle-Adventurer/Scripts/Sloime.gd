extends KinematicBody2D


enum {IDLE, CHASE}


const ACCELERATION = 100
const GRAVITY = 1000

var MAX_SPEED = 5
var velocity = Vector2.ZERO
var direction = Vector2.LEFT
var state = IDLE

var air := true
var turn := false

onready var level = get_node("/root/MainScene/Level1")
onready var player = get_node("/root/MainScene/Adventurer")

func _ready() -> void:
	global_position = Vector2(200,300)

func _physics_process(delta: float) -> void:
	match state:
		IDLE:
			_idle_state(delta)
		CHASE:
			_chase_state(delta)


func _update_direction_x() -> float:
	print(global_position)
	if state == IDLE:
		if turn:
			if direction.x > 0:
				direction.x = -1
			else:
				direction.x = 1
		if not turn:
			#print("yaas")
			return direction.x
		#elif turn and not air:
			#if direction.x > 0:
				#direction.x = -1
			#else:
				#direction.x = 1
		#return direction.x
	else:
		direction.x = player.global_position.x - global_position.x
		return direction.x
	return direction.x


func _basic_movement(delta) -> void:
	velocity = velocity.move_toward(direction * MAX_SPEED, ACCELERATION * delta)
	velocity.y += GRAVITY*delta
	velocity = move_and_slide(velocity, Vector2.UP)




func _idle_state(delta) -> void:
	MAX_SPEED = 5
	direction.x = _update_direction_x()
	velocity.x = move_toward(velocity.x, direction.x * MAX_SPEED, ACCELERATION*delta)
	velocity = move_and_slide(velocity, Vector2.UP)
	
	_basic_movement(delta)
	#vector så att det blir en båge
	var player_slime_distance = player.global_position - global_position
	
	if player_slime_distance.length() <= 600:
		state = CHASE
		return
	
	if is_on_floor():
		air = false
	else:
		air = true

func _chase_state(delta) -> void:
	MAX_SPEED = 10
	
	direction.x = _update_direction_x()
	velocity.x = move_toward(velocity.x, direction.x * MAX_SPEED, ACCELERATION*delta)
	velocity = move_and_slide(velocity, Vector2.UP)
	
	_basic_movement(delta)
	#vector så att det blir en båge
	var player_slime_distance = player.global_position - global_position
	
	if player_slime_distance.length() >= 600:
		state = IDLE
		return
	
	if is_on_floor():
		air = false
	else:
		air = true
	
	
	


"""
var direction_x = 1
var velocity = Vector2.ZERO
onready var player = get_node("/root/MainScene/Adventurer")
var taken_damage := false

const GRAVITY = 1000
const ACCELERATION = 1000
const MAX_SPEED = 50

func _ready() -> void:
	global_position = Vector2(300,300)

	
func _physics_process(delta: float) -> void:
	if taken_damage == true:
		print("velocity: ", velocity)
		taken_damage = false
	if player == null:
		return
	
	var player_slime_distance = player.global_position - global_position
	
	#vector så att det blir en båge
	if player_slime_distance.x <= 10 and player_slime_distance.x >= -10:
		direction_x = 0
	elif player_slime_distance.length() <= 600:
		if player.global_position.x - $Sprite.global_position.x < 0:
			direction_x = -1
		else:
			direction_x = 1
	else:
		direction_x = 0
	player_slime_distance.y = 0
	if direction_x != 0:
		velocity = move_toward(velocity, player_slime_distance * MAX_SPEED, ACCELERATION*delta)
	else:
		velocity = move_toward(velocity, 0, ACCELERATION*delta)
	if is_on_floor() and direction_x == 1:
		velocity.x -= 10
	elif is_on_floor():
		velocity.x += 10
	velocity.y += GRAVITY*delta
	velocity = move_and_slide(velocity, Vector2.UP)
	
	
	if direction_x < 0:
		$Sprite.set_flip_h(true)
	else:
		$Sprite.set_flip_h(false)




func _on_Area2D_body_entered(body: Node) -> void:
	var direction_to_player = player.global_position - global_position
	direction_to_player = direction_to_player.normalized()
	if body.is_in_group("Player"):
		body.take_damage(direction_to_player)
		velocity.x = direction_x * -100
		print("collision: ", direction_to_player)
		taken_damage = true




func die() -> void:
	queue_free()
"""

"""

enum {IDLE, RUN, AIR}

const MAX_SPEED = 100
const ACCELERATION = 1500
const GRAVITY = 1000

var direction_x = "RIGHT"
var velocity := Vector2.ZERO
var direction := Vector2.ZERO

var state = IDLE


func _physics_process(delta: float) -> void:
	match state:
		IDLE:
			_idle_state(delta)
		RUN:
			_run_state(delta)
		AIR:
			_air_state(delta)


#Help functions
func _apply_basic_movement(delta) -> void:
	if direction.x != 0:
		velocity = velocity.move_toward(direction*MAX_SPEED, ACCELERATION*delta)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, ACCELERATION*delta)
	
	velocity.y += GRAVITY*delta
	velocity = move_and_slide(velocity, Vector2.UP)

func _get_input_x_update_direction() -> float:
	var input_x = Input.get_axis("move_left", "move_right")
	if input_x > 0:
		direction_x = "RIGHT"
	elif input_x < 0:
		direction_x = "LEFT"
	$Sprite.flip_h = direction_x != "RIGHT"
	return input_x


func _air_movement(delta) -> void:
	velocity.y = velocity.y + GRAVITY * delta if velocity.y + GRAVITY * delta < 500 else 500 
	direction.x = _get_input_x_update_direction()
	if direction.x != 0:
		velocity.x = move_toward(velocity.x, direction.x * MAX_SPEED, ACCELERATION*delta)
	else:
		velocity.x = move_toward(velocity.x, 0, ACCELERATION * delta)
	velocity = move_and_slide(velocity, Vector2.UP)


#STATES:
func _idle_state(delta) -> void:
	direction.x = _get_input_x_update_direction()
		
	_apply_basic_movement(delta)
	
	if not is_on_floor():
		_enter_air_state(false)
		return
	if velocity.x != 0:
		_enter_run_state()
		return
		
func _run_state(delta) -> void:
	direction.x = _get_input_x_update_direction()
	
	_apply_basic_movement(delta)
	
	if not is_on_floor():
		_enter_air_state(false)
		return
	elif velocity.length() == 0:
		_enter_idle_state()
		return


func _air_state(delta) -> void:	
	if is_on_floor():
		_enter_idle_state()
		return
	

#Enter states
func _enter_idle_state() -> void:
	state = IDLE

func _enter_run_state() -> void:
	state = RUN


func _enter_air_state(jump: bool) -> void:
	state = AIR

"""


func _on_Area2D_body_exited(body: Node) -> bool:
	#if body.is_in_group("Tile"):
	print("okay")
	turn = true
	return turn
	#else:
		#return false
