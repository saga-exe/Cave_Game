extends CanvasLayer

var coins = 0

onready var healthbar = $HealthBar
onready var cointext = $CoinText


func _ready() -> void:
	healthbar.value = 100

func health_changed(hp) -> void:
	healthbar.value = hp

func gems_collected(coin) -> void:
	coins += coin
	cointext.text = "Coins: " + str(coins)
