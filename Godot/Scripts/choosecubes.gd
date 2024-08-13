extends Node3D

class_name OptionBlocks

signal change_block
signal hit_block

@export var blocks_nb : int
@export var cur_index : int = 0
@export var index_angle : float = 3.0
@export var center_point = Vector2(0.5,0)
@export var pos_offset : float = 10.0
@export var original_positions : Array[Vector3]
@export var offset_speed : float = 250
@export var distance_margin = 5.
@export var max_shadow_floor_distance = 2.0
var is_in_choosing_position = true
var is_moving = false
var choosen_floating_one_delta : float = 0.0
const BLOCKS_NAMES = ["HAMMER","BROS.","FLEE","ITEM","JUMP"] #HOW THE FUCK DOES THIS SHIT WORKS
const INT_EEE = [1,2,3,4,0] #HOW THE FUCK DOES THIS SHIT WORKS
const INT_NAME = [0,1,2,3,4]
@export_category("Debug")
@export var selected_block_index = 0
@export var selected_block_name = ""
@export var array_selected = 0

func get_choose_cube_name() -> String:
	return BLOCKS_NAMES[get_choose_cube()]

func get_choose_cube() -> int:
	return -cur_index % blocks_nb

func get_pos_by_angle(angle : float, circle_center : Vector2, circle_rayon : float) -> Vector2:
	var vec = Vector2.from_angle(deg_to_rad(angle))
	vec += circle_center
	vec *= circle_rayon
	return vec

func emit_hit_signal(_body):
	if _body is CharacterBody3D and is_in_choosing_position:
		hit_block.emit()
		$"Hitsound".play()
		#print_debug("TOUCHED")
		

func _ready():
	$Area3D.body_entered.connect(emit_hit_signal)
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
	#print_debug("PROCESS LOOP STARTS")
	var i = 0
	#print("E : ",cur_index, " <-> ", (-cur_index) % blocks_nb )

	choosen_floating_one_delta += _delta
	for object in get_children():
		if is_instance_of(object,StaticBody3D):
			var child : StaticBody3D = object
			#if child is StaticBody3D:
			var vec = get_pos_by_angle(i*index_angle + pos_offset,center_point,0.5)

			#region HOW THE FUCK DOES THIS SHIT WORKS
			if INT_EEE[get_choose_cube()] == i:
				array_selected = INT_EEE[get_choose_cube()]
				selected_block_name = get_choose_cube_name()
				child.global_position = Vector3(vec.x,position.y + sin(deg_to_rad(int(choosen_floating_one_delta*360) % 360))*0.02,vec.y)
			else:
				child.global_position = Vector3(vec.x,position.y,vec.y)
			#endregion HOW THE FUCK DOES THIS SHIT WORKS
			i += 1
	#print_debug("PROCESS LOOP ENDS : ",i)
	if Input.is_action_just_pressed(&"ui_left") and is_in_choosing_position:
		cur_index -= 1
		selected_block_index -= 1
		if selected_block_index < 0:
			selected_block_index = blocks_nb - 1
		change_block.emit(cur_index,-1)
		$"SwitchSound".pitch_scale = 0.5
		$"SwitchSound".play()
	if Input.is_action_just_pressed(&"ui_right") and is_in_choosing_position:
		cur_index += 1
		selected_block_index += 1
		if selected_block_index >= blocks_nb:
			selected_block_index = 0
		change_block.emit(cur_index,1)
		$"SwitchSound".pitch_scale = 0.5
		$"SwitchSound".play()
	
	if (pos_offset - index_angle*cur_index) > distance_margin or (pos_offset - index_angle*cur_index) < -distance_margin:
		pos_offset += sign(index_angle*cur_index - pos_offset) * _delta * offset_speed 
	else:
		pos_offset = index_angle * cur_index


func set_global_transparence(transparence : float):
	for object in get_children():
		if is_instance_of(object,StaticBody3D):
			var child : StaticBody3D = object
			child.get_node(^"./MeshInstance3D").set_transparency(transparence)