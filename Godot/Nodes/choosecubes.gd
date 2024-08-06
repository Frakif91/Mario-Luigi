extends Node3D

class_name OptionBlocks

@export var blocks_nb : int
@export var cur_index : int = 0
@export var index_angle : float = 3.0
@export var center_point = Vector2(0.5,0)
@export var pos_offset : float = 10.0
@export var original_positions : Array[Vector3]
@export var offset_speed : float = 3

func get_pos_by_angle(angle : float, circle_center : Vector2, circle_rayon : float) -> Vector2:
	var vec = Vector2.from_angle(deg_to_rad(angle))
	vec += circle_center
	vec *= circle_rayon
	return vec

func _ready():
	blocks_nb = 0
	original_positions.clear()
	for child in get_children():
		if is_instance_of(child,StaticBody3D):
			blocks_nb += 1
			original_positions.append(child.global_position)
	cur_index = 0

	#Ternary operator : Get the angles between blocks, if no blocks, use 360°
	index_angle = 360.0/float(blocks_nb) if blocks_nb != 0 else 360.0

func _process(_delta):
	var i = 0
	for child in get_children():
		if is_instance_of(child,StaticBody3D):
		#if child is StaticBody3D:
			var vec = get_pos_by_angle(i*index_angle + pos_offset,center_point,0.5)
			child.global_position = Vector3(vec.x,position.y,vec.y)
			i += 1
	if Input.is_action_pressed(&"ui_left"):
		pos_offset -= _delta * offset_speed
	if Input.is_action_pressed(&"ui_right"):
		pos_offset += _delta * offset_speed

