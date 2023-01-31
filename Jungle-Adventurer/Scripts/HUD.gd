extends CanvasLayer


onready var healthbar = $HealthBar


func _ready() -> void:
	healthbar.value = 100

func health_changed(hp) -> void:
	healthbar.value = hp
