extends Node3D

class_name  ASprite3D_to_2D

@export var sprite_frames : SpriteFrames
@onready var sprite3d : AnimatedSprite3D = $"AnimatedSprite3D"
@onready var sprite2d : AnimatedSprite2D = $"AnimatedSprite2D"

func play_both(animation : StringName, custom_speed : float = 1.0, from_end : bool = false):
	sprite2d.play(animation, custom_speed, from_end)
	sprite3d.play(animation, custom_speed, from_end)

func play_both_backwards(animation : StringName):
	sprite2d.play(animation, -1.0, true)
	sprite3d.play(animation, -1.0, true)

func call_both(method : StringName, args : Array):
	sprite2d.callv(method,args)
	sprite3d.callv(method,args)

# Called when the node enters the scene tree for the first time.
func _ready():
	sprite2d.sprite_frames = sprite_frames
	sprite3d.sprite_frames = sprite_frames

func _process(_delta):
	var cam : Camera3D = get_viewport().get_camera_3d()

	sprite2d.visible = not cam.is_position_behind(position)
	cam.unproject_position(position)
