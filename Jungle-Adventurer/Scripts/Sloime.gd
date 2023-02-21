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
var can_check_right := true
var can_check_left := true

onready var level = get_node("/root/MainScene/kronk/Platforms")
onready var player = get_node("/root/MainScene/Adventurer")
onready var TerrainCheck = $TerrainCheck
onready var TerrainCheck2 = $TerrainCheck2

func _ready() -> void:
	global_position = Vector2(800,200)
	$RayCast.set_collide_with_areas(true)
	$RayCast2.set_collide_with_areas(true)


func _physics_process(delta: float) -> void:
	print($RayCast.get_collision_point().y)
	match state:
		IDLE:
			_idle_state(delta)
		CHASE:
			_chase_state(delta)


func _update_direction_x(delta) -> float:
	var player_slime_distance = player.global_position - global_position
	if state == IDLE:
		if turn or wait:
			if last_direction > 0:
				direction.x = -1
			else:
				direction.x = 1
			turn = false
			wait = false
		if velocity.x == 0:
			direction.x = last_direction
			
	elif state == CHASE:
		if player_slime_distance.x < 5 and player_slime_distance.x > -5:
			direction.x = 0
		elif player_slime_distance.x < 0:
			direction.x = -1
		else:
			direction.x = 1
		
		if wait:
			velocity.x = 0
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
	
	_sprite_direction()

func _sprite_direction() -> void:
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
	if player_slime_distance.length() <= 600:
		state = CHASE
		return


func _chase_state(delta) -> void:
	MAX_SPEED = 100
	
	direction.x = _update_direction_x(delta)
	
	_basic_movement(delta)
	
	#vector så att det blir en båge
	var player_slime_distance = player.global_position - global_position
	
	if player_slime_distance.length() >= 600:
		if wait:
			wait = false
			direction.x = last_direction 
		state = IDLE
		return


func die() -> void:
	queue_free()


#turn behövs enbart då enemy ska vända vid slutet av en platform,
#ej då spelaren hamnar på andra sidan

"""
_on_Area2D_body_exited() kollar ifall TerrainCheck/TerrainCheck2 har lämnat platformen, aka slimen är påväg att åka av
- ifall state == IDLE ska turn vara true, wait false och can_drop false
- ifall state == CHASE ska turn vara false, och sedan cecka för platformar under och då bestämma om wait eller drop är true
- då drop == true så är (turn och wait) == false
- den droppar eftersom den aldrig kommer in på platformen och därför går inte terrancheck ut och stoppar slimen från att trilla
"""



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


func _on_KnockbackTimer_timeout() -> void:
	knockback = false

# terraincheck decides if turn or not, then state decides if turn or wait, and after state it should be decided if it drops or not ( raycast )

# det är om raycast är kortare än avståndet mellan slime och nedre kanten på skärmen som den kan droppa, ANNARS INTE


func _on_TerrainArea_body_entered(body):
	if body.is_in_group("Tile"):
		can_check_right = true


func _on_TerrainArea_body_exited(body):
	
	if state == IDLE:
		turn = true
	elif state == CHASE:
		if body.is_in_group("Tile"):
			turn = false
			if (last_direction > 0 and $RayCast.get_collision_point().y < 580):
				wait = false
				can_drop = true
			elif last_direction > 0:
				wait = true
				#can_drop = false
	can_check_right = false

# $RayCast2.get_collision_point().y finns inte

func _on_TerrainArea2_body_exited(body):
	 
	if state == IDLE:
		turn = true
	elif state == CHASE:
		if body.is_in_group("Tile"):
			turn = false
			if (last_direction < 0 and $RayCast2.get_collision_point().y < 580):
				print("ok")
				wait = false
				can_drop = true
			#else:
				#wait = true
				#can_drop = false
	can_check_left = false
