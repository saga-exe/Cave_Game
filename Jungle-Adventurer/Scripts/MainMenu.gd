extends Control


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	print("ready")


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


func _on_StartButton_pressed():
	print("ok")
	#Transition.load_scene("res://Scenes/MainScene.tscn")


func _on_Button_pressed():
	Transition.load_scene("res://Scenes/MainScene.tscn")
