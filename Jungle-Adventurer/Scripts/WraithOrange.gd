extends KinematicBody2D

enum {IDLE, CHASE, DIE}


const ACCELERATION = 500
var IDLE_SPEED = rand_range(30, 50)
var CHASE_SPEED = rand_range(80, 110)
var GRAVITY = 1000

var MAX_SPEED = 40
var velocity = Vector2.ZERO
var direction = Vector2.LEFT
var state = IDLE
var last_direction = 1
var turn_direction = 1
var knockback_direction = 1
var hp = 100
var difficulty = 0

var air := true
var turn := false
var wait := false
var knockback := false
var can_check_right := true
var can_check_left := true

onready var player = get_node("/root/MainScene/Adventurer")
onready var TerrainCheck = $TerrainCheck
onready var TerrainCheck2 = $TerrainCheck2
onready var sprite = $AnimatedSprite


func _ready():
	MAX_SPEED = IDLE_SPEED
	state = IDLE
	sprite.play("Idle")
	$HealthBar.visible = false
	difficulty = Globals.difficulty


func _physics_process(delta: float) -> void:
	if Globals.is_finished:
		queue_free()
	match state:
		IDLE:
			_idle_state(delta)
		CHASE:
			_chase_state(delta)
		DIE:
			_die_state(delta)


func _update_direction_x(delta) -> float:
	var player_slime_distance = player.global_position - global_position
	if state == IDLE:
		if turn:
			if last_direction > 0:
				direction.x = -1
			else:
				direction.x = 1
			turn = false
			
	elif state == CHASE:
		if (not can_check_left and velocity.x < 0) or (not can_check_right and velocity.x > 0):
			wait = true
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
			_sprite_right()
			if velocity.x > 0:
				knockback = false
		else:
			_sprite_left()
			if velocity.x < 0:
				knockback = false
			
	else:
		if velocity.x == 0:
			if last_direction < 0:
				_sprite_left()
			else:
				_sprite_right()
		elif velocity.x < 0:
			_sprite_left()
		else:
			_sprite_right()


func _sprite_right() -> void:
	sprite.set_flip_h(false)


func _sprite_left() -> void:
	sprite.set_flip_h(true)


func _idle_state(delta) -> void:
	_can_collide()
	MAX_SPEED = IDLE_SPEED
	direction.x = _update_direction_x(delta)
	
	_basic_movement(delta)
	
	#vector så att det blir en båge
	var player_slime_distance = player.global_position - global_position
	if player_slime_distance.length() <= 400 and not Globals.damaged:
		sprite.play("Walking")
		state = CHASE
		return
# if cant check left and velocity < 0 wait = true

func _chase_state(delta) -> void:
	_can_collide()
	if wait:
		sprite.play("Idle")
	else:
		sprite.play("Walking")
	MAX_SPEED = CHASE_SPEED
	
	direction.x = _update_direction_x(delta)
	
	_basic_movement(delta)
	
	#vector så att det blir en båge
	var player_slime_distance = player.global_position - global_position
	
	if player_slime_distance.length() >= 400 or Globals.damaged:
		sprite.play("Walking")
		if wait:
			wait = false
			turn = true
		state = IDLE
		return


func die() -> void:
	state = DIE


func _die_state(delta) -> void:
	$KinematicBody2D/PlayerCollision.disabled = true
	$WraithArea/CollisionShape2D.disabled = true
	$TopKill/CollisionShape2D.disabled = true
	set_collision_mask_bit(8, false)
	velocity.x = 0
	direction.x = 0
	sprite.play("Dying")
	yield(sprite,"animation_finished")
	queue_free()

#turn behövs enbart då enemy ska vända vid slutet av en platform,
#ej då spelaren hamnar på andra sidan

"""
_on_Area2D_body_exited() kollar ifall TerrainCheck/TerrainCheck2 har lämnat platformen, aka slimen är påväg att åka av
- ifall state == IDLE ska turn vara true, wait false och can_drop false
- ifall state == CHASE ska turn vara false, och sedan cecka för platformar under och då bestämma om wait eller drop är true
- då drop == true så är (turn och wait) == false
- den droppar eftersom den aldrig kommer in på platformen och därför går inte terraincheck ut och stoppar slimen från att trilla
"""



func _on_WraithArea_body_entered(body: Node) -> void:
	if body.is_in_group("Player"):
		knockback = true
		if player.global_position.x - global_position.x < 0:
			knockback_direction = -1
		else:
			knockback_direction = 1
		if (((global_position.y - 74.5) - player.global_position.y) < 5) and (((global_position.y - 74.5) - player.global_position.y) > -20) and player.velocity.y >= 0:
			body.take_damage(0, knockback_direction)
			die()
		else:
			set_collision_mask_bit(0, false)
			body.take_damage(25, knockback_direction)
			velocity.x = knockback_direction * -200

# terraincheck decides if turn or not, then state decides if turn or wait

func _on_TerrainArea_body_entered(body):
	if body.is_in_group("Tile"):
		can_check_right = true


func _on_TerrainArea2_body_entered(body):
	if body.is_in_group("Tile"):
		can_check_left = true


func _on_TerrainArea_body_exited(body):
	if body.is_in_group("Tile"):
		if state == IDLE:
			turn = true
		elif state == CHASE:
			turn = false
			wait = true
	can_check_right = false


func _on_TerrainArea2_body_exited(body):
	if body.is_in_group("Tile"):
		if state == IDLE:
			turn = true
		elif state == CHASE:
			wait = true
	can_check_left = false


func take_damage(damage) -> void:
	hp -= damage * (2 - difficulty)
	$HealthBar.value = hp
	if hp < 100:
		$HealthBar.visible = true
	else:
		$HealthBar.visible = false
	if hp <= 0:
		state = DIE


func _on_TopKillArea_body_entered(body: Node) -> void:
	if body.is_in_group("Player") and ((global_position.y - player.global_position.y) > 55):
		GRAVITY = 0
		knockback = true
		if player.global_position.x - global_position.x < 0:
			knockback_direction = -1
		else:
			knockback_direction = 1
		body.take_damage(0, knockback_direction)
		$TopKill/CollisionShape2D.disabled = true
		$TopKill/TopKillArea/CollisionShape2D.disabled = true
		$TileCollision.disabled = true
		$KinematicBody2D/PlayerCollision.disabled = true
		$WraithArea/CollisionShape2D.disabled = true
		state = DIE


func _can_collide() -> void:
	if not Globals.can_collide:
		$KinematicBody2D/PlayerCollision.disabled = true
		$WraithArea/CollisionShape2D.disabled = true
	else:
		$KinematicBody2D/PlayerCollision.disabled = false
		$WraithArea/CollisionShape2D.disabled = false
