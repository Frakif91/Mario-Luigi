@tool
extends AnimatedSprite3D


# Called when the node enters the scene tree for the first time.
func _ready():
	animation_changed.connect(func(): play(&""))
