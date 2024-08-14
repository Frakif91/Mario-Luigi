extends CharacterBody3D

@onready var asprite3D : AnimatedSprite3D = $"ASprite3D"
@onready var jumpsfx : AudioStreamPlayer = $"JumpSFX"
@export var center_fall_anim_rspeed : float = 0.3

const DIRECTION : Dictionary = {UP = &"N", DOWN = &"S", LEFT = &"L", RIGHT = &"R",
								UPLEFT = &"NL", UPRIGHT = &"NR", DOWNLEFT = &"SL", DOWNRIGHT = &"SR"}
const ACTIONS : Dictionary = {JUMP = &"jump", IDLE = &"idle", WALK = &"walk"}
enum ALTERNATIVE {NORMAL,ALT,ALT2,ALT3}

var state_direction : StringName = &"S"
var state_action : StringName = &"idle"
var on_floor : bool
var just_touched_floor : bool
var jump_alt = -1
var can_play_animation = true

signal touched_floor

@export var SPEED = 5.0
@export var JUMP_VELOCITY = 4.5

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

func animation_process():
	get_action_and_direction(Vector2(sign(velocity.x),sign(velocity.z)))

	if just_touched_floor:
		play_animation(ACTIONS.JUMP,state_direction,&"2")
		can_play_animation = false
		#await asprite3D.animation_finished
		can_play_animation = true
	elif state_action == ACTIONS.WALK:
		play_animation(state_action,state_direction,&"")
	elif state_action == ACTIONS.IDLE:
		play_animation(state_action,state_direction,&"0")
	elif state_action == ACTIONS.JUMP:
		play_animation(state_action,state_direction,str(jump_alt))

func _process(_delta):
	if can_play_animation:
		await animation_process()

func _physics_process(delta):
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta

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
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()
	
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
	
	if not cur_direction and is_on_floor(): #NO DIRECTION
		state_action = ACTIONS.IDLE
		return

	elif cur_direction and is_on_floor():
		state_action = ACTIONS.WALK
	elif not is_on_floor():
		state_action = ACTIONS.JUMP

	if cur_direction:
		match cur_direction:
			Vector2(1,0): state_direction = DIRECTION.RIGHT
			Vector2(-1,0): state_direction = DIRECTION.LEFT
			Vector2(0,-1): state_direction = DIRECTION.UP
			Vector2(0,1): state_direction = DIRECTION.DOWN
			
			Vector2(1,1): state_direction = DIRECTION.DOWNRIGHT
			Vector2(-1,1): state_direction = DIRECTION.DOWNLEFT
			Vector2(1,-1): state_direction = DIRECTION.UPRIGHT
			Vector2(-1,-1): state_direction = DIRECTION.UPLEFT


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
	
	asprite3D.play(StringName(composed_animation_name))
	
