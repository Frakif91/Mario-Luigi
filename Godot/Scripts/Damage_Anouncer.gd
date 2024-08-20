extends Control

class_name DamageAnnouncer

@onready var display : TextureNumber = $"Damage"
@onready var background : DamageAnouncerTexture = $"Background"
@onready var animationplayer = $"AnimationPlayer"

# var max_lifetime = 1.5
# var lifetime = 0.0
# enum BackGroundTexture {MARIO,LUIGI,DAMAGE,TOTAL}

# Called when the node enters the scene tree for the first time.
func create(pos3d : Vector3, damage_value : int, bg_type : int):
	await Globals.wait(0.01)
	#visible = get_viewport().get_camera_3d().is_position_behind(pos3d)
	position = get_viewport().get_camera_3d().unproject_position(pos3d)
	print_debug("POSITION DAMAGE : ",position)
	background.cur_bg_tex = bg_type as DamageAnouncerTexture.BackGroundTexture
	display.value = damage_value

func showup():
	animationplayer.play(&"new_animation")
	await animationplayer.animation_finished
	queue_free()
	



