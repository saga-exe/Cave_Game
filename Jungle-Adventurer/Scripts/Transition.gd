extends CanvasLayer

onready var animationplayer = $AnimationPlayer

var level_scene = preload("res://Scenes/Level1.tscn")
var level = 1


"""
Denna funktion anropas av scenen som spelas innan denna för att uppdatera
vilken level spelaren är på.
"""
func level(level_number) -> void:
	level = level_number


"""
Denna funktion utför övergågnen mellan scener. Den gör skärmen röd medan den laddar,
och om det inte är "MainScene", alltså en level, som laddas, så sätts den globala
variabeln is_finished till true för att allt i leveln ska tas bort.

Sedan byts scenen genom att anväda den path som gavs då funktionen anropades.
Om en level är nästa scen så ställs några globala variabler in som sedan anropas
i Adventurer-scriptet.

Då scenen instansierats så fadear den röda färgen och spelet kan användas igen.
"""
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
			Globals.level = 0
		elif level == 1:
			level_scene = preload("res://Scenes/Level1.tscn")
			Globals.start_pos = Vector2(190, 453)
			Globals.camera_limit = 11808
			Globals.level = 1
		elif level == 2:
			level_scene = preload("res://Scenes/Level2.tscn")
			Globals.start_pos = Vector2(190, 229)
			Globals.camera_limit = 12000
			Globals.level = 2
		var level_instance = level_scene.instance()
		get_tree().get_root().add_child(level_instance)
		level_instance.global_position = Vector2(0, 0)
	animationplayer.play_backwards("fade_in")
	

