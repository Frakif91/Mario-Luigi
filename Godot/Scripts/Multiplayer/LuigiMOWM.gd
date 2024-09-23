class_name Luigi_Multiplayer_Movement extends CharacterBody3D

var movement_buffer : Array[Vector3]

@onready var asprite3D : AnimatedSprite3D = $"ASprite3D"

@export var SPEED = 6.0 * 10
@export var array_lenght = 20
@export_node_path("Mario_Multiplayer_Movement") var mario_np :
	set(new_path):
		mario = get_node_or_null(new_path)
		if mario:
			pass
			#update_multiplayer_mario_entity()
@onready var mario : Mario_Multiplayer_Movement
var old_position : Vector3
var is_mario_walking

func _ready() -> void:
	if mario:
		mario.did_move.connect(_luigi_global_movement)
		mario.start_move.connect(func():is_mario_walking = true)
		mario.stop_move.connect(func():is_mario_walking = false; velocity.x = 0; velocity.z = 0)

func _luigi_relative_movement(_velocity : Vector3):
	old_position = global_position
	movement_buffer.push_front(_velocity)

	if movement_buffer.size() >= array_lenght:
		var movement = movement_buffer.pop_back()
		r_movement(movement.x, movement.z)

func _luigi_global_movement(_position):
	old_position = global_position
	movement_buffer.push_front(_position)
	
	if movement_buffer.size() >= array_lenght:
		var movement = movement_buffer.pop_back()
		g_movement(movement.x, movement.z)
		#global_position = movement
		#await animation_process()

func _physics_process(delta: float) -> void:
	velocity.y += delta * get_gravity().y
	move_and_slide()

	if is_on_floor() and Input.is_action_just_pressed((Globals.Bros.get("Luigi") as Brother).action_button):
		velocity.y = 4.5
		$"JumpSFX".play()

const DIRECTION : Dictionary = {UP = &"N", DOWN = &"S", LEFT = &"L", RIGHT = &"R",
								UPLEFT = &"NL", UPRIGHT = &"NR", DOWNLEFT = &"SL", DOWNRIGHT = &"SR"}
const ACTIONS : Dictionary = {JUMP = &"jump", IDLE = &"idle", WALK = &"walk"}
enum ALTERNATIVE {NORMAL,ALT,ALT2,ALT3}

var state_direction : StringName = &"S"
var state_action : StringName = &"idle"
var on_floor : bool
var just_touched_floor : bool
var jump_alt = 0
var can_play_animation = true

const SORTED_DIRECTION = ["E", "NE", "N", "NW", "W", "SW", "S", "SE"]

func g_movement(inputx,inputy):
	global_position.x += clampf(inputx - global_position.x, -SPEED, SPEED)
	global_position.z += clampf(inputy - global_position.z, -SPEED, SPEED)
	#animation_process(global_position.x, global_position.z)

func r_movement(inputx, inputy):
	#var move = (transform.basis * Vector3(inputx, 0, inputy)).normalized()
	velocity.x = clampf(inputx - global_position.x, -SPEED, SPEED)
	velocity.z = clampf(inputy - global_position.z, -SPEED, SPEED)
	#animation_process(global_position.x, global_position.z)

func animation_process(inputx,inputy):
	get_action_and_direction(Vector2(sign(old_position.x - inputx),sign( old_position.z - inputy)))

	# if just_touched_floor:
	# 	play_animation(ACTIONS.JUMP,state_direction,&"2")
	# 	can_play_animation = false
	# 	#await asprite3D.animation_finished-1
	# 	can_play_animation = true
	if state_action == ACTIONS.WALK:
		play_animation(state_action,state_direction,&"")
		$"Timer".start()
	elif state_action == ACTIONS.IDLE:
		play_animation(state_action,state_direction,&"0")
		#cur_right_foot = true
		$"Timer".stop()
	elif state_action == ACTIONS.JUMP:
		play_animation(state_action,state_direction,str(jump_alt))

func _process(_delta):
	if can_play_animation:
		await animation_process(global_position.x, global_position.z)


func get_action_and_direction(cur_direction : Vector2):
	#var last_angle = movement_buffer
	if not is_on_floor():
		state_action = ACTIONS.JUMP

	elif not is_mario_walking: #NO DIRECTION
		state_action = ACTIONS.IDLE
		return

	elif is_mario_walking:
		state_action = ACTIONS.WALK
	

	#thx to (https://gamedev.stackexchange.com/questions/49290/whats-the-best-way-of-transforming-a-2d-vector-into-the-closest-8-way-compass-d)
	if cur_direction:
		var cur_angle = atan2( cur_direction.y * -1, cur_direction.x);
		var octant = roundi( 8 * cur_angle / (2*PI) + 4 ) % 8;
	
		state_direction = SORTED_DIRECTION[octant]

func play_animation(action : StringName, _direction : StringName, _animation_alt : StringName):
	var does_have_alt : bool = false
	var does_have_direction : bool = false
	
	if not _animation_alt.is_empty():
		does_have_alt = true
	
	if not _direction.is_empty():
		does_have_direction = true
	
	var composed_animation_name : String

	if does_have_direction and does_have_alt:
		composed_animation_name = "-".join(PackedStringArray([action,_direction,_animation_alt]))
	elif does_have_direction and not does_have_alt:
		composed_animation_name = "-".join(PackedStringArray([action,_direction]))
	else:
		composed_animation_name = action
	
	if asprite3D.animation != composed_animation_name:
		var old_frame = asprite3D.get_frame()
		var old_progress = asprite3D.get_frame_progress()
		asprite3D.play(StringName(composed_animation_name))
		if composed_animation_name.begins_with("walk") and asprite3D.animation.begins_with("walk"):
			asprite3D.set_frame_and_progress(old_frame,old_progress)
