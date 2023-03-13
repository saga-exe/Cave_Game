extends CanvasLayer

var coins = -1

onready var healthbar = $HealthBar
onready var cointext = $CoinText


func _ready() -> void:
	healthbar.value = 100

func _process(delta):
	_power_up()

func health_changed(hp) -> void:
	healthbar.value = hp

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
