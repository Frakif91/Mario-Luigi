extends Control

var trans_ready_time = Globals.trans_ready_time

# Called when the node enters the scene tree for the first time.
func _ready():
	await get_tree().create_timer(1).timeout
	($AnimationPlayer as AnimationPlayer).play(&"new_animation",-1,-1.0,true)
