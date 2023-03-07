extends KinematicBody2D

onready var player = get_node("/root/MainScene/Adventurer")
var wraith_orange_scene = preload("res://Scenes/WraithOrange.tscn")
var wraith_teal_scene = preload("res://Scenes/WraithTeal.tscn")
var coin_scene = preload("res://Scenes/Coin.tscn")
var firesmall_scene = preload("res://Scenes/FireSmall.tscn")
var firemedium_scene = preload("res://Scenes/FireMedium.tscn")

var furthest_position_x = 0

func _ready() -> void:
	pass 

func _physics_process(delta: float) -> void:
	if global_position.x < 1200:
		global_position.x += 3000*delta
	elif player.global_position.x > global_position.x - 600:
		global_position.x = player.global_position.x + 600
	if Globals.finished():
		queue_free()
	

func _slime_collision(body, tile_number) -> void:
	if body.is_in_group("WraithOrangeSpawn"):
		var wraith_instance = wraith_orange_scene.instance()
		get_tree().get_root().add_child(wraith_instance)
		wraith_instance.global_position = Vector2(global_position.x, 32*tile_number - 10)
	elif body.is_in_group("WraithTealSpawn"):
		var wraith_instance = wraith_teal_scene.instance()
		get_tree().get_root().add_child(wraith_instance)
		wraith_instance.global_position = Vector2(global_position.x, 32*tile_number - 10)
	elif body.is_in_group("CoinSpawn"):
		var coin_instance = coin_scene.instance()
		get_tree().get_root().add_child(coin_instance)
		coin_instance.global_position = Vector2(global_position.x, 32*tile_number + 10)
	elif body.is_in_group("FireSmall"):
		var fire_instance = firesmall_scene.instance()
		get_tree().get_root().add_child(fire_instance)
		fire_instance.global_position = Vector2(global_position.x, 32*tile_number + 15)
	elif body.is_in_group("FireMedium"):
		var fire_instance = firemedium_scene.instance()
		get_tree().get_root().add_child(fire_instance)
		fire_instance.global_position = Vector2(global_position.x, 32*tile_number + 5)


func _on_Tile1_body_entered(body: Node) -> void:
	_slime_collision(body, 0)


func _on_Tile2_body_entered(body: Node) -> void:
	_slime_collision(body, 1)


func _on_Tile3_body_entered(body: Node) -> void:
	_slime_collision(body, 2)


func _on_Tile4_body_entered(body: Node) -> void:
	_slime_collision(body, 3)


func _on_Tile5_body_entered(body: Node) -> void:
	_slime_collision(body, 4)



func _on_Tile6_body_entered(body: Node) -> void:
	_slime_collision(body, 5)


func _on_Tile7_body_entered(body: Node) -> void:
	_slime_collision(body, 6)


func _on_Tile8_body_entered(body: Node) -> void:
	_slime_collision(body, 7)


func _on_Tile9_body_entered(body: Node) -> void:
	_slime_collision(body, 8)


func _on_Tile10_body_entered(body: Node) -> void:
	_slime_collision(body, 9)


func _on_Tile11_body_entered(body: Node) -> void:
	_slime_collision(body, 10)


func _on_Tile12_body_entered(body: Node) -> void:
	_slime_collision(body, 11)


func _on_Tile13_body_entered(body: Node) -> void:
	_slime_collision(body, 12)


func _on_Tile14_body_entered(body: Node) -> void:
	_slime_collision(body, 13)


func _on_Tile15_body_entered(body: Node) -> void:
	_slime_collision(body, 14)


func _on_Tile16_body_entered(body: Node) -> void:
	_slime_collision(body, 15)


func _on_Tile17_body_entered(body: Node) -> void:
	_slime_collision(body, 16)


func _on_Tile18_body_entered(body: Node) -> void:
	_slime_collision(body, 17)
