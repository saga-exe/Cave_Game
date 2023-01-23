extends KinematicBody2D


enum {IDLE, CHASE}


const ACCELERATION = 500
const GRAVITY = 1000

var MAX_SPEED = 40
var velocity = Vector2.ZERO
var direction = Vector2.LEFT
var state = IDLE
var last_direction = 1
var turn_direction = 1

var air := true
var turn := false
var wait := false

onready var level = get_node("/root/MainScene/Level1")
onready var player = get_node("/root/MainScene/Adventurer")

func _ready() -> void:
	global_position = Vector2(100,300)

func _physics_process(delta: float) -> void:
	match state:
		IDLE:
			_idle_state(delta)
		CHASE:
			_chase_state(delta)


func _update_direction_x() -> float:
	if state == IDLE:
		if turn:
			if direction.x > 0:
				direction.x = -1
			else:
				direction.x = 1
			turn = false
			
	elif state == CHASE:
		if player.global_position.x - global_position.x < 0:
			direction.x = -1
		else:
			direction.x = 1
		
		if turn and global_position.y < 520:
			turn = false
		elif turn and global_position.y > 520: #and last_direction == direction.x:
			turn = false
			wait = true
				
			
		if wait:
			if last_direction == direction.x:
				direction.x = 0
			
			else:
				wait = false
				turn = false
		
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
	
	if velocity.x < 0:
		$Sprite.set_flip_h(true)
		$TerrainCheck.position = Vector2(-50,40)
	else:
		$Sprite.set_flip_h(false)
		$TerrainCheck.position = Vector2(50,40)




func _idle_state(delta) -> void:
	MAX_SPEED = 40
	direction.x = _update_direction_x()
	
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
	MAX_SPEED = 60
	
	direction.x = _update_direction_x()
	
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
onready var player = get_node("/root/MainScene/Adventurer")
var taken_damage := false


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

#turn behövs enbart då enemy ska vända vid slutet av en platform,
#ej då spelaren hamnar på andra sidan

func _on_Area2D_body_exited(body: Node) -> void:
	if state == IDLE:
		turn = true
		
		print("okay")

	return

