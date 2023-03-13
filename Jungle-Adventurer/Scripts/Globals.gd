extends Node

var difficulty_number = 0
var is_finished := false
var level_scene = preload("res://Scenes/Level1.tscn")

func get_difficulty(difficulty_get) -> void:
	difficulty_number = difficulty_get

func difficulty() -> float:
	return difficulty_number

func finish() -> void:
	is_finished = true

func antifinish() -> void:
	is_finished = false

func finished() -> bool:
	return is_finished
