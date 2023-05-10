extends Control

"""
Gör så att tangenterna rör på sig i rätt ordning.
"""
func _ready():
	$"BasicMovement/W".set_frame(0)
	$"BasicMovement/A".set_frame(3)
	$"BasicMovement/D".set_frame(1)
	
