extends Node

#globala variablar

var difficulty = 0 #svårighetsgrad
var level = 0 #vilken level som ska spelas
var is_finished := false #om leveln avslutas (avklarad eller game over)
var level_scene = preload("res://Scenes/Level1.tscn") #leveln som ska laddas in och spelas
var can_collide := true #om spelaren kan kollidera med fiender
var damaged := false #om spelaren är skadad och inte kan ta mer skada
var y_move = 0 #hur spelaren rör sig i y-led
var power = "none" #om spelaren har en powerup
var start_pos = Vector2(190, 453) #spelarens startposition som varierar beroende på level
var camera_limit = 3200 #hur långt till höger kameran kan gå
var highscore = 0
var score = 1
