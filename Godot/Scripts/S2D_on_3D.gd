extends Node3D

class_name  S2D_on_3D

func _process(_delta):
	var cam : Camera3D = get_viewport().get_camera_3d()

	if not get_child_count():
		return

	for child in get_children():
		if child is Node2D:
			#child.visible = not cam.is_position_behind(position)
			child.position = cam.unproject_position(position)
