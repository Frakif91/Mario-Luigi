extends Control

var trans_ready_time = Globals.trans_ready_time

# Called when the node enters the scene tree for the first time.
func _ready():
	await get_tree().create_timer(1).timeout
	$AnimationPlayer.play(&"new_animation")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _input(_event):
	if Input.is_action_just_pressed(&"TestButton1"):
		$AnimationPlayer.play(&"new_animation")