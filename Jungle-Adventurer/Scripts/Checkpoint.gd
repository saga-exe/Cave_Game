extends Area2D

onready var player = get_node("/root/MainScene/Adventurer")
var lower_sound := false #om true så håller ljudvolymen på att säknas. ljudet det används för är ljudfilen av att elden startar.
var lit := false #om true så är checkpointen "tagen"

func _ready():
	$Light2D.visible = false #checkpointen lyser inte eftersom det inte är taget än.
	$AnimatedSprite.play("Unlit") #checkpointen är inte tänd


func _on_Checkpoint_body_entered(body):
	if body.is_in_group("Player") and not lit: #när spelaren går förbi tas checkpointen och ljud samt eld börjar spela
		$SoundTimer.start()
		$LightFire.play()
		$Light2D.visible = true
		$AnimatedSprite.play("Lit")
		player.last_pos = global_position #sparar spelarens position som den senaste (spelaren kommer att respawna vid detta checkpoint om den trillar ned i lavan
		lit = true


func _physics_process(_delta: float) -> void:
	if lower_sound and not $Fire.playing: #då ljudet på att elden startar försvinner byts det ut mot en brinnande eld
		$Fire.play()
	if $Fire.playing and $Fire.volume_db < 6: #ljudet på den tända elden ökar tills det kommer till det satta nivån
		$Fire.volume_db += 0.1
	if lower_sound: #volymen på tändljuset säkns
		$LightFire.volume_db -= 0.1
	if Globals.is_finished: #då leveln avslutas (avklarad eller game over) startas en timer för att leveln och allt i den inte ska försvinna direkt. Då timern tar slut så försvinner allt
		$FinishTimer.start()


#Då timern stannar så tas checkpointen bort
func _on_FinishTimer_timeout():
	queue_free()


#ljudet på att elden tänds börjar säknas då det gått en viss tid
func _on_SoundTimer_timeout() -> void:
	lower_sound = true
