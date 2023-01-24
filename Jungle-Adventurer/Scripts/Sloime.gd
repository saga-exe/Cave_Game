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
onready var TerrainCheck = $TerrainCheck
onready var TerrainCheck2 = $TerrainCheck2

func _ready() -> void:
	global_position = Vector2(100,512)

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
			
		if wait:
			if last_direction == direction.x:
				direction.x = 0
			
			else:
				wait = false
		
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
	else:
		$Sprite.set_flip_h(false)




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




func die() -> void:
	queue_free()


#turn behövs enbart då enemy ska vända vid slutet av en platform,
#ej då spelaren hamnar på andra sidan

func _on_Area2D_body_exited(body: Node) -> void:
	if state == IDLE:
		if state == IDLE:
			turn = true
	elif state == CHASE:
		if body.is_in_group("Tile"):
			wait = true
		elif body.is_in_group("Tile"):
			wait = true
	return



func _on_Area2D_body_entered(body: Node) -> void:
	if body.is_in_group("Player"):
		var direction_to_player = player.global_position - global_position
		direction_to_player = direction_to_player.normalized()
		body.take_damage()
		velocity.x = direction.x * -100
		if (((global_position.y-45) - player.global_position.y) < 20) and (((global_position.y-45) - player.global_position.y) > 0):
			die()
			
