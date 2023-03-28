extends Control

func _ready():
	hide()



func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_tree().paused = !get_tree().paused
		if get_tree().paused:
			show()
		else:
			hide()

func _on_QuitButton_pressed():
	get_tree().quit()


func _on_ResumeButton_pressed():
	get_tree().paused = !get_tree().paused
	hide()


func _on_MainMenuButton_pressed():
	get_tree().paused = !get_tree().paused
	Transition.load_scene("res://Scenes/MainMenu.tscn")
