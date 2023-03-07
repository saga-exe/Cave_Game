extends Control

var difficulty = 1

onready var DIFFICULTY = $Difficulty
onready var layer1 = $Node/ParallaxBackground/ParallaxLayer1
onready var layer2 = $Node/ParallaxBackground/ParallaxLayer2
onready var layer3 = $Node/ParallaxBackground/ParallaxLayer3
onready var layer4 = $Node/ParallaxBackground/ParallaxLayer4
onready var layer5 = $Node/ParallaxBackground2/ParallaxLayer5
onready var layer6 = $Node/ParallaxBackground2/ParallaxLayer6


func _physics_process(delta: float) -> void:
	layer1.motion_offset.x += 40*delta
	layer2.motion_offset.x += 30*delta
	layer3.motion_offset.x += 20*delta
	layer4.motion_offset.x += 10*delta
	layer5.motion_offset.x += 5*delta
	layer6.motion_offset.x += 5*delta
	
	if difficulty == 0.5:
		DIFFICULTY.text = "Easy"
	elif difficulty == 1:
		DIFFICULTY.text = "Normal"
	elif difficulty == 1.5:
		DIFFICULTY.text = "Hard"
	else:
		DIFFICULTY.text = "Super Hard"
		


func _on_StartButton_pressed():
	Globals.get_difficulty(difficulty)
	Transition.load_scene("res://Scenes/MainScene.tscn")
	


func _on_LowerDifficulty_pressed() -> void:
	if difficulty > 0.5:
		difficulty -= 0.5


func _on_HigherDifficulty_pressed() -> void:
	if difficulty < 2:
		difficulty += 0.5


func _on_QuitButton_pressed() -> void:
	get_tree().quit()
