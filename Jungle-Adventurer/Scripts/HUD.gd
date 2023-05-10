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


"""
Då tutorial (level == 0) spelas så finns ej score, highscore eller tid, vilket
gör att de då inte är synliga. Då en level 1 0ch 2 spelas så ska de visas.
"""
func _ready() -> void:
	if Globals.level == 0: #då tut
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
		$highscore.visible = true
		$TimeDivider2.visible = true
		$TimeDivider1.visible = true
		$Minutes.visible = true
		$MilliSeconds.visible = true
		$Seconds.visible = true
		$highscoretext.visible = true
		$score.visible = true
		$scoretext.visible = true
	$highscore.text = str(highscore)
	healthbar.value = 100 #fyller healthbar då leveln startar
	attackbar.value = 8 #fyller manabar då leveln startar


"""
Denna funktion kallar på funktioner för att hålla HUDen uppdaterad för spelaren.
_time() uppdaterar tiden och _power_up() uppdaterar så att spelaren kan se på 
HUDen om den har en powerup. 

Här uppdateras även score och ändrar så att spelaren ser den uppdaterade scoren
hela tiden.
"""
func _process(delta):
	_time(delta)
	_power_up()
	score = 180000 - minutes * 60 * 100 - seconds * 100 - milliseconds + coins * 1500 - (100 - healthbar.value) * 250
	if score <= 0:
		Globals.score = 0
		player._finished_state(delta)
	$score.text = str(stepify(score, 1))

func health_changed(hp) -> void: #denna funktion kallas från Advenurer-scriptet då hp förändras
	healthbar.value = hp

func mana_changed(mana) -> void: #denna funktion kallas i _physics_process i Adventurer-scriptet och uppdaterar attackbaren hela tiden
	attackbar.value = mana

func gems_collected(coin) -> void: #gems_collected() anropas av Coin-scriptet då spelaren går in i dess area och plockar upp den
	coins += coin                  #antal coins tagna ökar då med 1 och HUDen uppdateras
	cointext.text = str(coins) 


"""
_time() - funktionen uppdaterar tiden som spelaren ser. Det används variabler för
varje "tidsdel" (sek, min etc.) för att underlätta att skriva ut tiden i samma
font som de andra sakerna i HUDen. varje del skrivs då ut för sig själv. 

Då t.ex. sekunder når 60 så återställs sekunder och minuter blir 1 större.

Denna funktion skriver även ut ändringarna i HUDen.
"""
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


"""
_power_up() visar en animation av powerupen som är tagen på HUDen för att
förtydliga för spelaren. Då spelaren inte har en powerup spelas animation
"default", vilken inte visar någonting alls.
"""
func _power_up() -> void:
	if Globals.power == "none":
		$PowerUp.play("default")
	elif Globals.power == "star":
		$PowerUp.play("Star")
	elif Globals.power == "speed":
		$PowerUp.play("Speed")


"""
Den här funktionen laddar highscore från en save file. Först definierar den
FILE_PATH, och sedan ändras den till rätt file path beroende på vilken level som
spelas. Efter det öppnas filen för att läsa in highscore, och sedan stängs filen.

Den laddas i av _ready() - funktionen och uppdaterar även den globala highscore-variabeln.
"""
func _load_highscore() -> void:
	var FILE_PATH = SAVE_FILE_LEVEL1
	if Globals.level == 2:
		FILE_PATH = SAVE_FILE_LEVEL2
	var save_file = File.new()
	if save_file.file_exists(FILE_PATH):
		save_file.open(FILE_PATH, File.READ)
		highscore = save_file.get_var()
		save_file.close()
	else:
		highscore = 0
	Globals.highscore = highscore


"""
Den här funktionen spara highscore i en save file. Först definierar den
FILE_PATH, och sedan ändras den till rätt file path beroende på vilken level som
spelas. Efter det öppnas filen för att spara highscore, och sedan stängs filen.

Den anropas av Adventurer-scriptet då en level är aklarad och spelaren fick ett
högre score än det nuvarande highscoret.
"""
func save_highscore() -> void:
	score = 180000 - minutes * 60 * 100 - seconds * 100 - milliseconds + coins * 1500 - (100 - healthbar.value) * 250
	if score > Globals.highscore:
		var FILE_PATH = SAVE_FILE_LEVEL1
		if Globals.level == 2:
			FILE_PATH = SAVE_FILE_LEVEL2
		var save_file = File.new()
		save_file.open(FILE_PATH, File.WRITE)
		save_file.store_var(stepify(score, 1))
		save_file.close()
		Globals.score = stepify(score, 1)
