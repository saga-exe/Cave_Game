extends CanvasLayer

onready var animationplayer = $AnimationPlayer

var level_scene = preload("res://Scenes/Level1.tscn")
var level = 1

func level(level_number) -> void:
	level = level_number


func load_scene(path):
	animationplayer.play("fade_in")
	yield(animationplayer, "animation_finished")
	get_tree().change_scene(path)
	if path == "res://Scenes/MainScene.tscn":
		if level == 2:
			level_scene = preload("res://Scenes/Level2.tscn")
		var level_instance = level_scene.instance()
		get_tree().get_root().add_child(level_instance)
		level_instance.global_position = Vector2(0, 0)
	animationplayer.play_backwards("fade_in")
	

