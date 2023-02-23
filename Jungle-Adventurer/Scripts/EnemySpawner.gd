extends KinematicBody2D

onready var player = get_node("/root/MainScene/Adventurer")
var slime_scene = preload("res://Scenes/Sloime.tscn")
#var slime_instance = slime_scene.instance()

var player_position_x = 0

func _ready() -> void:
	pass 

func _physics_process(delta: float) -> void:
	
	if player.global_position.x > player_position_x:
		player_position_x = player.global_position.x + 600
	if global_position.x <= 1200:
		global_position.x += 1200*delta
	#elif global_position < player_position_x
	#print($Tile1.global_position)

#func _gb() -> float:
	#var gb = global_position.x
	#return gb

func _on_EnemySpawner_body_entered(body: Node) -> void:
	if body.is_in_group("Slimespawn"):
		var slime_instance = slime_scene.instance()
		get_tree().get_root().add_child(slime_instance)
		slime_instance.global_position = Vector2($CollisionShape2D.global_position.x, 300)
		print(body.global_position)
		
		
	print("spawn")

"""
func _on_Tile1_body_entered(body: Node) -> void:
	if body.is_in_group("Slimespawn"):
		var slime_instance = slime_scene.instance()
		get_tree().get_root().add_child(slime_instance)
		slime_instance.global_position = $Tile1.global_position
"""

func _on_Tile16_body_entered(body: Node) -> void:
	var glob = global_position.x
	if body.is_in_group("Slimespawn"):
		var slime_instance = slime_scene.instance()
		get_tree().get_root().add_child(slime_instance)
		#var gb = global_position.x
		print(global_position.x)
		slime_instance.global_position = Vector2(glob, 15*32)
		
		#slime_instance.velocity = Vector2(0,0)
		#print($Tile16.global_position)
		return
