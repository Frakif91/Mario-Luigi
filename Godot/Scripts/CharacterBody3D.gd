extends CharacterBody3D

class_name BrotherCB3

const SPEED = 5.0
const JUMP_VELOCITY = 4.5
const GRAVITY_MULT = 1.2

var og_position : Vector3
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var affected_by_gravity = true

@onready var animated_sprite : AnimatedSprite3D = $AnimatedSprite3D

@export_category("Character Stats")
@export var character_name : StringName = "Mario"
@export var hp : int = 21:
	set(new_hp):
		hp = clampi(new_hp,0,max_hp)
	get:
		return hp
@export var bp : int = 18
@export var max_hp : int = 36
@export var max_bp : int = 24
@export var attack : int = 13
@export var defense : int = 15
@export var speed : int = 10
@export var level : int = 5
@export var xp : int = 300
@export var xp_to_next_level : int = 80

@export_category("Other")
@export var overrite_animation = false
@export var can_jump = true
@export var chooseblock_offset : Vector3
@export var camera_position : Vector3

#ANIMATION BEHAVIOR
enum states {IDLE,TIRED,KO} 
@export var cur_state : states

func update_state() -> states:
	if hp <= 0: cur_state = states.KO
	elif hp <= ceili(max_hp*0.3): cur_state = states.TIRED
	else: cur_state = states.IDLE
	return cur_state

# Get the gravity from the project settings to be synced with RigidBody nodes.

func _physics_process(delta):
	# Add the gravity.
	if not is_on_floor() and not Globals.MARIO.overrite_animation:
		velocity.y -= gravity*GRAVITY_MULT * delta

		if Input.is_action_just_pressed(&"Jump") and is_on_floor() and Globals.MARIO.can_jump:
			velocity.y = JUMP_VELOCITY
			$"AudioStreamPlayer".play()

	if not overrite_animation:
		if Globals.RPG.combat_state == Globals.RPG.combat_turn.PLAYER_CHOOSING: # and is_on_floor():
			if update_state() == states.TIRED:
				animated_sprite.play(&"thinking-tired")
			else:
				animated_sprite.play(&"thinking")
		else:
			if update_state() == states.TIRED:
				animated_sprite.play(&"idle-tired")
			else:
				animated_sprite.play(&"idle")

		if not is_on_floor():
			animated_sprite.play(&"jump-up-right")
			

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	# var input_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	# var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	# if direction:
	# 	velocity.x = direction.x * SPEED
	# 	velocity.z = direction.z * SPEED
	# else:
	# 	velocity.x = move_toward(velocity.x, 0, SPEED)
	# 	velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()
