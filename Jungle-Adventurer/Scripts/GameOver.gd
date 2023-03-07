extends Control


onready var layer1 = $Node/ParallaxBackground/ParallaxLayer1
onready var layer2 = $Node/ParallaxBackground/ParallaxLayer2
onready var layer3 = $Node/ParallaxBackground/ParallaxLayer3
onready var layer4 = $Node/ParallaxBackground/ParallaxLayer4
onready var layer5 = $Node/ParallaxBackground2/ParallaxLayer5
onready var layer6 = $Node/ParallaxBackground2/ParallaxLayer6


func _physics_process(delta: float) -> void:
	layer1.motion_offset.x += 10*delta
	layer2.motion_offset.x += 20*delta
	layer3.motion_offset.x += 30*delta
	layer4.motion_offset.x += 40*delta
	layer5.motion_offset.x += 50*delta
	layer6.motion_offset.x += 50*delta
