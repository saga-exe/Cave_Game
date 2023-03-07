extends Node

var difficulty = 0
var finished := false

func get_difficulty(difficulty_get) -> void:
	difficulty = difficulty_get

func difficulty() -> float:
	return difficulty

func finish() -> void:
	finished = true

func finished() -> bool:
	return finished
