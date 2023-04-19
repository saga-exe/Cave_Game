extends CanvasLayer

var coins = 0
var time = 0
var milliseconds = 0
var seconds = 0
var minutes = 0
var score = 0
var highscore = 0

const SAVE_FILE_LEVEL1 = "user://DungeonSlayer_1_File.save"
const SAVE_FILE_LEVEL2 = "user://DungeonSlayer_2_File.save"

onready var healthbar = $HealthBar
onready var cointext = $CoinText
onready var attackbar = $ExtraAttackBar
onready var player = get_node("/root/MainScene/Adventurer")


func _ready() -> void:
	if Globals.level == 0:
		$highscore.visible = false
		$TimeDivider2.visible = false
		$TimeDivider1.visible = false
		$Minutes.visible = false
		$MilliSeconds.visible = false
		$Seconds.visible = false
		$highscoretext.visible = false
		$score.visible = false
		$scoretext.visible = false
	else:
		_load_highscore()
	$highscore.text = str(highscore)
	healthbar.value = 100
	attackbar.value = 8

func _process(delta):
	_time(delta)
	_power_up()
	score = 180000 - minutes * 60 * 100 - seconds * 100 - milliseconds + coins * 500 - (100 - healthbar.value) * 500
	if score <= 0:
		Globals.score = 0
		player._finished_state(delta)
	$score.text = str(stepify(score, 1))

func health_changed(hp) -> void:
	healthbar.value = hp

func mana_changed(mana) -> void:
	attackbar.value = mana

func gems_collected(coin) -> void:
	coins += coin
	cointext.text = str(coins)

func _time(delta) -> void:
	milliseconds += delta * 100
	if milliseconds >= 100:
		milliseconds = 0
		seconds += 1
	if seconds >= 60:
		seconds = 0
		minutes += 1
	if milliseconds < 10:
		$MilliSeconds.text = "0" + str(stepify(milliseconds, 1))
	else:
		$MilliSeconds.text = str(stepify(milliseconds, 1))
	if seconds < 10:
		$Seconds.text = "0" + str(seconds)
	else:
		$Seconds.text = str(seconds)
	if minutes < 10:
		$Minutes.text = "0" + str(minutes)
	else:
		$Minutes.text = str(minutes)

func _power_up() -> void:
	if Globals.power == "none":
		$PowerUp.play("default")
	elif Globals.power == "star":
		$PowerUp.play("Star")
	elif Globals.power == "speed":
		$PowerUp.play("Speed")


func _load_highscore() -> void:
	var FILE_PATH = SAVE_FILE_LEVEL1
	if Globals.level == 1:
		FILE_PATH = SAVE_FILE_LEVEL1
	elif Globals.level == 2:
		FILE_PATH = SAVE_FILE_LEVEL2
	var save_file = File.new()
	if save_file.file_exists(FILE_PATH):
		save_file.open(FILE_PATH, File.READ)
		highscore = save_file.get_var()
		save_file.close()
	else:
		highscore = 0
	Globals.highscore = highscore

func save_highscore() -> void:
	score = 180000 - minutes * 60 * 100 - seconds * 100 - milliseconds + coins * 500 - (100 - healthbar.value) * 500
	if score > Globals.highscore:
		var FILE_PATH = SAVE_FILE_LEVEL1
		if Globals.level == 2:
			FILE_PATH = SAVE_FILE_LEVEL2
		var save_file = File.new()
		save_file.open(FILE_PATH, File.WRITE)
		save_file.store_var(stepify(score, 1))
		save_file.close()
		Globals.score = stepify(score, 1)
