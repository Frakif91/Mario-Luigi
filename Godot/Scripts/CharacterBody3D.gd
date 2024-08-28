class_name BrotherCB3 extends CharacterBody3D

const SPEED = 5.0
const JUMP_VELOCITY = 4.5
const GRAVITY_MULT = 1.2


var og_position : Vector3
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var affected_by_gravity = true

@onready var animated_sprite : AnimatedSprite3D = $AnimatedSprite3D

#ANIMATION BEHAVIOR
enum states {IDLE,TIRED,KO}
#var camera_position = {OG = Vector3(1.,1.4,2.), T_ENEMY = Vector3(1.4,1.4,2.2), OUT = Vector3(1,2,3),LUIGI = Vector3(0.5,1.4,2.5)}

@export_enum("Mario","Luigi") var who = "Mario"
@export var cur_state : states

func update_state() -> states:
	if bro.hp <= 0: cur_state = states.KO
	elif bro.hp <= ceili(bro.max_hp*0.3): cur_state = states.TIRED
	else: cur_state = states.IDLE
	return cur_state

var bro : Globals.Brother

func _ready():
	if who == "Mario":
		# bro = CharacterDefaultStats.new().create_character(CharacterDefaultStats.available.MARIO)
		var test = Globals.Bros.get("Mario")
		bro = test
		bro.camera_position = Vector3(1.,1.4,2.)
		og_position = position

	if who == "Luigi":
		var test = Globals.Bros.get("Luigi")
		bro = test
		bro.camera_position = Vector3(0.5,1.4,2.5)
		og_position = position
	
	bro.og_position = og_position

	
	#bro.camera_position = position #+ Vector3(1,2,2)

# Get the gravity from the project settings to be synced with RigidBody nodes.

func _physics_process(delta):
	# Add the gravity.
	if not is_on_floor() and not bro.overrite_animation:
		velocity.y -= gravity*GRAVITY_MULT * delta

	if Input.is_action_just_pressed(bro.action_button) and is_on_floor() and bro.can_jump:
		velocity.y = JUMP_VELOCITY
		$"AudioStreamPlayer".play()

	if not bro.overrite_animation:
		if Globals.RPG.combat_state == Globals.RPG.combat_turn.PLAYER_CHOOSING and Globals.cur_brother == self: # and is_on_floor():
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
