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
var knockback_direction = 1

var air := true
var turn := false
var wait := false
var knockback := false
var can_drop := false

onready var level = get_node("/root/MainScene/kronk/Platforms")
onready var player = get_node("/root/MainScene/Adventurer")
onready var TerrainCheck = $TerrainCheck
onready var TerrainCheck2 = $TerrainCheck2

func _ready() -> void:
	global_position = Vector2(800,200)


func _physics_process(delta: float) -> void:
	match state:
		IDLE:
			_idle_state(delta)
		CHASE:
			_chase_state(delta)


func _update_direction_x(delta) -> float:
	var player_slime_distance = player.global_position - global_position
	_can_drop()
	if state == IDLE:
		if wait:
			wait = false
			turn = true
		if turn:
			if last_direction > 0 or velocity.x > 0:
				direction.x = -1
			else:
				direction.x = 1
			turn = false
		if velocity.x == 0:
			direction.x = last_direction
			
	elif state == CHASE:
		if player_slime_distance.x < 5 and player_slime_distance.x > -5:
			if direction.x != 0:
				last_direction = direction.x
			direction.x = 0
		elif player_slime_distance.x < 0:
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
	
	if knockback:
		if knockback_direction > 0:
			$Sprite.set_flip_h(false)
			if velocity.x > 0:
				knockback = false
		else:
			$Sprite.set_flip_h(true)
			if velocity.x < 0:
				knockback = false
			
	else:
		if velocity.x == 0:
			if last_direction < 0:
				$Sprite.set_flip_h(true)
			else:
				$Sprite.set_flip_h(false)
		elif velocity.x < 0:
			$Sprite.set_flip_h(true)
		else:
			$Sprite.set_flip_h(false)




func _idle_state(delta) -> void:
	MAX_SPEED = 40
	direction.x = _update_direction_x(delta)
	
	_basic_movement(delta)
	
	#vector så att det blir en båge
	var player_slime_distance = player.global_position - global_position
	if player_slime_distance.length() <= 200:
		state = CHASE
		return
	
	if is_on_floor():
		air = false
	else:
		air = true



func _chase_state(delta) -> void:
	MAX_SPEED = 100
	
	direction.x = _update_direction_x(delta)
	
	_basic_movement(delta)
	
	#vector så att det blir en båge
	var player_slime_distance = player.global_position - global_position
	
	if player_slime_distance.length() >= 200:
		if wait:
			turn = true
			wait = false
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
		if knockback:
			wait = false
	return


#body

func _on_Area2D_body_entered(body: Node) -> void:
	
	if get_collision_mask_bit(0):
		var damage = 0
		if body.is_in_group("Player"):
			knockback = true
			if player.global_position.y > global_position.y:
				print("yeooo")
			if player.global_position.x - global_position.x < 0:
				knockback_direction = -1
			else:
				knockback_direction = 1
			if (((global_position.y-45) - player.global_position.y) < 5) and (((global_position.y-45) - player.global_position.y) > -20):
				damage = 0
				body.take_damage(damage, knockback_direction)
				die()
			else:
				damage = 25
				body.take_damage(damage, knockback_direction)
				velocity.x = knockback_direction * -200
	else:
		return
		

func _on_KnockbackTimer_timeout() -> void:
	knockback = false


func _can_drop() -> void:
	var length_raycast = ($RayCast.get_collision_point().y - $RayCast.global_position.y)
	var length_raycast2 = ($RayCast2.get_collision_point().y - $RayCast2.global_position.y)
	if (length_raycast < 800 and length_raycast > 30) or (length_raycast2 < 800 and length_raycast2 > 30):
		if state == CHASE:
			if global_position.y < 410:
				wait = false
				can_drop = true
		else:
			turn = true


