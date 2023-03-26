extends Node

var difficulty = 0
var level = 0
var is_finished := false
var level_scene = preload("res://Scenes/Level1.tscn")
var can_collide := true
var damaged := false
var y_move = 0
var power = "none"
var start_pos = Vector2(190, 485)
var camera_limit = 3200
