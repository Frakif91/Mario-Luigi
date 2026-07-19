class_name LuigiOW_Movement
extends OWCharacterMovement

signal on_new_trail_follow(coord : Vector3)

## Suit la trace laissée par Mario (mario.trail). Se déplace via velocity +
## move_and_slide(), donc soumis à de vraies collisions : si Luigi est trop
## large pour passer là où Mario est passé, il se coince réellement, ce qui
## est précisément ce qui fait que la laisse de Mario a un effet.

@export_node_path("MarioOW_Movement") var mario_np: NodePath
## Distance en dessous de laquelle on considère qu'un point de la trace est
## atteint, et qu'on peut le retirer pour viser le suivant.
@export var arrival_threshold: float = 0.15

@onready var mario: MarioOW_Movement = get_node_or_null(mario_np)
@onready var action_button: StringName = (Globals.Bros.get("Luigi") as Brother).action_button

var debugdraw := DebugDraw3D.new()

func _ready() -> void:
	get_tree().current_scene.add_child(debugdraw)
	Debugger.add_text("luigis_way", "Velocity")
	sorted_direction = [&"E", &"NE", &"N", &"NW", &"W", &"SW", &"S", &"SE"]

	if mario == null:
		push_warning("LuigiOW_Movement (%s) : Mario introuvable via mario_np, Luigi ne bougera pas." % [name])

func _physics_process(delta: float) -> void:
	super._physics_process(delta)

	if is_on_floor() and Input.is_action_just_pressed(action_button):
		try_jump()

	var is_walking := false

	if mario != null and not mario.trail.is_empty():
		var target: Vector3 = mario.trail[0]
		var to_target := target - global_position
		to_target.y = 0.0

		if to_target.length() <= arrival_threshold:
			mario.trail.pop_front()
			on_new_trail_follow.emit(target)
			debugdraw.draw_sphere_s
		else:
			velocity.x = clampf(to_target.x, -SPEED, SPEED)
			velocity.z = clampf(to_target.z, -SPEED, SPEED)
			Debugger.modify_text("luigis_way", "Target Velocity : \n\tX : " + String.num(velocity.x, 1) + "\n\tZ : " + String.num(velocity.z, 1) + "\n\tDistance : " + String.num(to_target.length(), 1))
			
			is_walking = true

	if not is_walking:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()

	update_action_and_direction(Vector2(roundi(velocity.x), roundi(velocity.z)).normalized(), is_walking)
