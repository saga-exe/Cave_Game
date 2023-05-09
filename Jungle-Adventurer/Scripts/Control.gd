extends Control

#script för pausmeny

func _ready(): #då spelet körs syns inte menyn
	hide()


func _unhandled_input(event: InputEvent) -> void: 
	if event.is_action_pressed("ui_cancel"): #då ESC klickas så pausar spelet och menyn visas, och om det redan är pausat så återupptas spelet och menyn försvinner.
		get_tree().paused = !get_tree().paused
		if get_tree().paused:
			show()
		else:
			hide()

func _on_QuitButton_pressed(): #om spelaren trycker på quit så avslutas spelet
	get_tree().quit()


func _on_ResumeButton_pressed(): #om splearen trycker på denna knapp så återupptas spelet där det var
	get_tree().paused = !get_tree().paused
	hide()


func _on_MainMenuButton_pressed(): #om spelaren trycker på denna knapp så kommer den tillbaka till startmenyn
	get_tree().paused = !get_tree().paused
	Transition.load_scene("res://Scenes/MainMenu.tscn")
