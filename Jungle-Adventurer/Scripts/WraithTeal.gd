extends KinematicBody2D

# it doesn't wait after knockback
# drops to die from idle to chase - fixed

#fix jump on head
#fix direction change after knockback

enum {IDLE, CHASE, DIE}


const ACCELERATION = 500
const GRAVITY = 1000

var MAX_SPEED = 20
var velocity = Vector2.ZERO
var direction = Vector2.LEFT
var state = IDLE
var last_direction = 1
var turn_direction = 1
var knockback_direction = 1
var hp = 100

var air := true
var turn := false
var wait := false
var knockback := false
var can_check_right := true
var can_check_left := true
var can_attack := true

var bullet_scene = preload("res://Scenes/WraithBullet.tscn")

onready var level = get_node("/root/MainScene/Level1/Platforms")
onready var player = get_node("/root/MainScene/Adventurer")
onready var TerrainCheck = $TerrainCheck
onready var TerrainCheck2 = $TerrainCheck2
onready var sprite = $AnimatedSprite


func _ready():
	state = IDLE
	sprite.play("Idle")
	$HealthBar.visible = false



func _physics_process(delta: float) -> void:
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
	$CastPoint.position.x = 10


func _sprite_left() -> void:
	sprite.set_flip_h(true)
	$CastPoint.position.x = -10


func _idle_state(delta) -> void:
	MAX_SPEED = 20
	direction.x = _update_direction_x(delta)
	
	_basic_movement(delta)
	
	#vector så att det blir en båge
	var player_slime_distance = player.global_position - global_position
	if player_slime_distance.length() <= 400 and player.get_collision_mask_bit(1):
		sprite.play("Walking")
		state = CHASE
		return
# if cant check left and velocity < 0 wait = true

func _chase_state(delta) -> void:
	if wait:
		sprite.play("Idle")
	else:
		sprite.play("Walking")
	MAX_SPEED = 50
	
	direction.x = _update_direction_x(delta)
	
	_basic_movement(delta)
	_attack()
	
	#vector så att det blir en båge
	var player_slime_distance = player.global_position - global_position
	
	if player_slime_distance.length() >= 400 or player.get_collision_mask_bit(1) == false:
		sprite.play("Walking")
		if wait:
			wait = false
			turn = true
		state = IDLE
		return


func die() -> void:
	state = DIE


func _die_state(delta) -> void:
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
- den droppar eftersom den aldrig kommer in på platformen och därför går inte terrancheck ut och stoppar slimen från att trilla
"""



func _on_Area2D_body_entered(body: Node) -> void:
	var damage = 0
	if body.is_in_group("Player"):
		knockback = true
		if player.global_position.x - global_position.x < 0:
			knockback_direction = -1
		else:
			knockback_direction = 1
		if (((global_position.y - 74.5) - player.global_position.y) < 5) and (((global_position.y - 74.5) - player.global_position.y) > -20) and player.velocity.y >= 0:
			damage = 0
			body.take_damage(damage, knockback_direction)
			die()
		else:
			set_collision_mask_bit(0, false)
			damage = 25
			body.take_damage(damage, knockback_direction)
			velocity.x = knockback_direction * -200

# terraincheck decides if turn or not, then state decides if turn or wait, and after state it should be decided if it drops or not ( raycast )

# det är om raycast är kortare än avståndet mellan slime och nedre kanten på skärmen som den kan droppa, ANNARS INTE


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


func _attack() -> void:
	if can_attack:
		var target = Vector2(player.global_position.x, player.global_position.y)
		sprite.play("SpellCast")
		var bullet_instance = bullet_scene.instance()
		bullet_instance.global_position = $CastPoint.global_position
		bullet_instance.set_direction($CastPoint.global_position, target)
		get_tree().get_root().add_child(bullet_instance)
		$ShootTimer.start()
		can_attack = false


func _on_ShootTimer_timeout():
	can_attack = true


func take_damage(damage) -> void:
	hp -= damage
	$HealthBar.value = hp
	if hp < 100:
		$HealthBar.visible = true
	else:
		$HealthBar.visible = false
	if hp <= 0:
		state = DIE
