extends Node3D

class_name  S2D_on_3D

@export_node_path("Node2D","Control") var affected_node_np
@onready var affected_node = get_node(affected_node_np)

func _process(_delta):
	var cam : Camera3D = get_viewport().get_camera_3d()

	#child.visible = not cam.is_position_behind(position)
	affected_node.position = cam.unproject_position(position)
