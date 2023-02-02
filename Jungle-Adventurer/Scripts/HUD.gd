extends CanvasLayer

var gems = 0

onready var healthbar = $HealthBar
onready var gemtext = $GemText


func _ready() -> void:
	healthbar.value = 100

func health_changed(hp) -> void:
	healthbar.value = hp

func gems_collected(gem) -> void:
	gems += gem
	gemtext.text = "Gems: " + str(gems)
