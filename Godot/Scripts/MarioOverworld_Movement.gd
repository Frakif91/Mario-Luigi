class_name MarioOW_Movement extends CharacterBody3D

signal did_move(velocity : Vector3)

signal start_move()
signal stop_move()

@onready var asprite3D : AnimatedSprite3D = $"ASprite3D"
@onready var jumpsfx : AudioStreamPlayer = $"JumpSFX"
@export var center_fall_anim_rspeed : float = 0.3
@export var walk_sound_waittime = 12.0/20./2.
@export_node_path("LuigiOW_Movement") var luigi_np
var luigi : LuigiOW_Movement 
@export var max_distance_from_luigi = 0.6
@export var max_distance_margin = 0.1
var cur_right_foot = false
var old_debug_direction = 0.0

class MarioMovement:
	var animation
	var glb_position
	var rel_position

const SORTED_DIRECTION = ["N","NE","E","SE","S","SW","W","NW"]

const ACTIONS : Dictionary = {JUMP = &"jump", IDLE = &"idle", WALK = &"walk"}
enum ALTERNATIVE {NORMAL,ALT,ALT2,ALT3}

var state_direction : StringName = &"S"
var state_action : StringName = &"idle"
var on_floor : bool
var just_touched_floor : bool
var jump_alt = 0
var is_moving = false
var can_play_animation = true

signal touched_floor

@export var SPEED = 5.0
@export var JUMP_VELOCITY = 4.5

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

func walk_sound():
	if cur_right_foot:
		$"RightFoot".play()
	else:
		$"RightFoot2".play()
	cur_right_foot = not cur_right_foot
	$"Timer".start(walk_sound_waittime)

func _ready():
	if luigi_np:
		luigi = get_node_or_null(luigi_np)
	$"Timer".timeout.connect(walk_sound)
	$"Timer".autostart = false
	$"Timer".one_shot = true
	stop_move.connect($"Timer".stop)
	start_move.connect(func(): $"Timer".start(walk_sound_waittime/2))
	#$"Timer".start(walk_sound_waittime)
	#$"Timer".stop()

func animation_process():
	get_action_and_direction(Vector2(sign(velocity.x),sign(velocity.z)))

	if just_touched_floor:
		play_animation(ACTIONS.JUMP,state_direction,&"2")
		can_play_animation = false
		#await asprite3D.animation_finished
		can_play_animation = true
	elif state_action == ACTIONS.WALK:
		play_animation(state_action,state_direction,&"")
		#$"Timer".start()
	elif state_action == ACTIONS.IDLE:
		play_animation(state_action,state_direction,&"0")
		cur_right_foot = true
		#$"Timer".stop()
	elif state_action == ACTIONS.JUMP:
		play_animation(state_action,state_direction,str(jump_alt))

func _process(_delta):
	if can_play_animation:
		await animation_process()

func _physics_process(delta):
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta

	if $"Timer".time_left > 0:
		if not is_on_floor():
			$"Timer".paused = true
		else:
			if $"Timer".paused:
				$"Timer".paused = false
				$"Timer".start(walk_sound_waittime/2)

	# Handle jump.
	if Input.is_action_just_pressed(&"Jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		jumpsfx.play()

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
		#did_move.emit(velocity)
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)
		if is_moving:
			is_moving = false
			stop_move.emit()

	# if self.global_position.distance_squared_to(luigi.global_position) >= max_distance_from_luigi:
	# 	var new_position = global_position + luigi.global_position.direction_to(self.global_position) * (max_distance_from_luigi - max_distance_margin)
	# 	velocity = new_position * 0.2

	move_and_slide()

	if velocity.x or velocity.z:
		did_move.emit(global_position)
		if not is_moving:
			is_moving = true
			start_move.emit()

	if is_on_ceiling_only():
		for slide_col_idx in get_slide_collision_count():
			var slide_col = get_slide_collision(slide_col_idx).get_collider()
			if is_instance_of(slide_col,OW_Block):
				(slide_col as OW_Block).block_hit.emit()
	
	just_touched_floor = false
	if on_floor != is_on_floor():
		on_floor = not on_floor
		if on_floor:
			touched_floor.emit()
			just_touched_floor = true
	
	if not is_on_floor():
		if velocity.y > center_fall_anim_rspeed:
			jump_alt = ALTERNATIVE.NORMAL
		elif velocity.y <= center_fall_anim_rspeed and velocity.y >= -center_fall_anim_rspeed: # -0.2 < velocity.y < 0.1
			jump_alt = ALTERNATIVE.ALT
		elif velocity.y < -center_fall_anim_rspeed:
			jump_alt = ALTERNATIVE.ALT2
			
		if just_touched_floor:
			jump_alt = ALTERNATIVE.ALT3
		

func get_action_and_direction(cur_direction : Vector2):
	var direction_angle = roundi(rad_to_deg(cur_direction.angle()))

	if not cur_direction and is_on_floor(): #NO DIRECTION
		state_action = ACTIONS.IDLE
		return

	elif cur_direction and is_on_floor():
		state_action = ACTIONS.WALK
	elif not is_on_floor():
		state_action = ACTIONS.JUMP

	var max_angles = 8
	var each_index = 360/max_angles

	state_direction = SORTED_DIRECTION[((direction_angle/each_index) + 2) % 8]
	
	#print("Mario -> Cur Angle : ",direction_angle, " <-> ", direction_angle/each_index ," <->", state_direction)

	# if cur_direction:
	# 	match cur_direction:
	# 		Vector2(1,0): state_direction = DIRECTION.RIGHT
	# 		Vector2(-1,0): state_direction = DIRECTION.LEFT
	# 		Vector2(0,-1): state_direction = DIRECTION.UP
	# 		Vector2(0,1): state_direction = DIRECTION.DOWN
			
	# 		Vector2(1,1): state_direction = DIRECTION.DOWNRIGHT
	# 		Vector2(-1,1): state_direction = DIRECTION.DOWNLEFT
	# 		Vector2(1,-1): state_direction = DIRECTION.UPRIGHT
	# 		Vector2(-1,-1): state_direction = DIRECTION.UPLEFT


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
		var old_frame = asprite3D.frame
		@warning_ignore("unused_variable")
		var old_progress = asprite3D.frame_progress
		asprite3D.play(StringName(composed_animation_name))
		if composed_animation_name.begins_with("walk") and asprite3D.animation.begins_with("walk"):
			asprite3D.set_frame_and_progress(old_frame,1)
			
	
