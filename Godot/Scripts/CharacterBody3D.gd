extends CharacterBody3D

class_name BrotherCB3

const SPEED = 5.0
const JUMP_VELOCITY = 4.5
const GRAVITY_MULT = 1.2

@export var who = Globals.BROTHER.MARIO
@export var affected_by_gravity = true

@onready var animated_sprite : AnimatedSprite3D = $AnimatedSprite3D
#@onready var animation_player = $""

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

func _ready():
	if who == Globals.BROTHER.MARIO:
		Globals.MARIO.og_position = position
	elif who == Globals.BROTHER.LUIGI:
		Globals.LUIGI.og_position = position

func _physics_process(delta):
	# Add the gravity.
	if not is_on_floor() and not Globals.MARIO.overrite_animation:
		velocity.y -= gravity*GRAVITY_MULT * delta

	if who == Globals.BROTHER.MARIO:
		if Input.is_action_just_pressed(&"Jump") and is_on_floor() and Globals.MARIO.can_jump:
			velocity.y = JUMP_VELOCITY
			$"AudioStreamPlayer".play()
		if not Globals.MARIO.overrite_animation:
			if Globals.RPG.combat_state == Globals.RPG.combat_turn.PLAYER_CHOOSING: # and is_on_floor():
				if Globals.MARIO.update_state() == Globals.MARIO.states.TIRED:
					animated_sprite.play(&"thinking-tired")
				else:
					animated_sprite.play(&"thinking")
			else:
				if Globals.MARIO.update_state() == Globals.MARIO.states.TIRED:
					animated_sprite.play(&"idle-tired")
				else:
					animated_sprite.play(&"idle")

			if not is_on_floor():
				animated_sprite.play(&"jump-up-right")
	elif who == Globals.BROTHER.LUIGI:
		if Input.is_action_just_pressed(&"Jump") and is_on_floor() and Globals.LUIGI.can_jump:
			velocity.y = JUMP_VELOCITY
			$"AudioStreamPlayer".play()
		if not Globals.LUIGI.overrite_animation:
			if Globals.RPG.combat_state == Globals.RPG.combat_turn.PLAYER_CHOOSING: # and is_on_floor():
				if Globals.LUIGI.update_state() == Globals.LUIGI.states.TIRED:
					animated_sprite.play(&"thinking-tired")
				else:
					animated_sprite.play(&"thinking")
			else:
				if Globals.LUIGI.update_state() == Globals.LUIGI.states.TIRED:
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
