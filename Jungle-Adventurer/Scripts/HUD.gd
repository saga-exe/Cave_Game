extends CanvasLayer

var coins = 0

onready var healthbar = $HealthBar
onready var cointext = $CoinText
onready var attackbar = $ExtraAttackBar


func _ready() -> void:
	healthbar.value = 100
	attackbar.value = 8

func _process(_delta):
	_power_up()

func health_changed(hp) -> void:
	healthbar.value = hp

func mana_changed(mana) -> void:
	attackbar.value = mana

func gems_collected(coin) -> void:
	coins += coin
	cointext.text = str(coins)

func _power_up() -> void:
	if Globals.power == "none":
		$PowerUp.play("default")
	elif Globals.power == "star":
		$PowerUp.play("Star")
	elif Globals.power == "speed":
		$PowerUp.play("Speed")
