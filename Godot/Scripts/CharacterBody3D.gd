extends CharacterBody3D


const SPEED = 5.0
const JUMP_VELOCITY = 4.5
const GRAVITY_MULT = 1.2

const animations = ["jump-up-right","idle"]

@onready var animati = $AnimatedSprite3D
@onready var animation_player = $""

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")


func _physics_process(delta):
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity*GRAVITY_MULT * delta

	# Handle jump.
	if Input.is_action_just_pressed(&"Jump") and is_on_floor() and Globals.MARIO.can_jump:
		velocity.y = JUMP_VELOCITY
		$"AudioStreamPlayer".play()
	if not Globals.MARIO.mario_overrite_animation:
		if Globals.RPG.combat_state == Globals.RPG.combat_turn.PLAYER_CHOOSING: # and is_on_floor():
			$AnimatedSprite3D.play(&"thinking")
		else:
			$AnimatedSprite3D.play(&"idle")
		if not is_on_floor():
			$AnimatedSprite3D.play(&"jump-up-right")


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