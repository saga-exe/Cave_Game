extends KinematicBody2D

var direction_x = 1
var velocity = Vector2.ZERO
onready var player = get_node("/root/MainScene/Adventurer")

const GRAVITY = 1000
const ACCELERATION = 1500
const MAX_SPEED = 100

func _ready() -> void:
	global_position = Vector2(300,300)

	
func _physics_process(delta: float) -> void:
	if player == null:
		return
	var player_slime_distance = player.global_position - global_position
	#vector så att det blir en båge
	if player_slime_distance.length() <= 600:
		if player.global_position.x - $Sprite.global_position.x < 0:
			direction_x = -1
		else:
			direction_x = 1
	if not is_on_floor():
		velocity.y = velocity.y + GRAVITY * delta if velocity.y + GRAVITY * delta < 500 else 500 

	velocity.x = move_toward(velocity.x, direction_x * MAX_SPEED, ACCELERATION*delta)
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
		velocity.x = direction_to_player.x * -400
		print("collision: ", direction_to_player)

		

func die() -> void:
	queue_free()




