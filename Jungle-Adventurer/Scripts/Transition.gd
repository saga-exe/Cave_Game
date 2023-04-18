extends CanvasLayer

onready var animationplayer = $AnimationPlayer

var level_scene = preload("res://Scenes/Level1.tscn")
var level = 1

#it goes around bcos yield

func level(level_number) -> void:
	level = level_number


func load_scene(path):
	animationplayer.play("fade_in")
	if not path == "res://Scenes/MainScene.tscn":
		Globals.is_finished = true
	yield(animationplayer, "animation_finished")
	get_tree().change_scene(path)
	if path == "res://Scenes/MainScene.tscn":
		if level == 0:
			level_scene = preload("res://Scenes/LevelTutorial.tscn")
			Globals.start_pos = Vector2(190, 453)
			Globals.camera_limit = 5220
		elif level == 1:
			level_scene = preload("res://Scenes/Level1.tscn")
			Globals.start_pos = Vector2(190, 453)
			Globals.camera_limit = 11808
		elif level == 2:
			level_scene = preload("res://Scenes/Level2.tscn")
			Globals.start_pos = Vector2(190, 229)
			Globals.camera_limit = 12000
		var level_instance = level_scene.instance()
		get_tree().get_root().add_child(level_instance)
		level_instance.global_position = Vector2(0, 0)
	animationplayer.play_backwards("fade_in")
	

