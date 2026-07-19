class_name OWCharacterMovement
extends CharacterBody3D

## Base commune à Mario et Luigi : gravité, saut, et machine d'état
## d'animation à 8 directions. Chaque enfant reste responsable de son
## propre input / logique de déplacement horizontal.

signal touched_floor

const ACTIONS: Dictionary = {JUMP = &"jump", IDLE = &"idle", WALK = &"walk"}
enum ALTERNATIVE {NORMAL, ALT, ALT2, ALT3}

@export var SPEED: float = 5.0
@export var JUMP_VELOCITY: float = 4.5
@export var center_fall_anim_rspeed: float = 0.3

@onready var asprite3D: AnimatedSprite3D = $"ASprite3D"
@onready var jumpsfx: AudioStreamPlayer = $"JumpSFX"

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

var state_direction: StringName = &"S"
var state_action: StringName = &"idle"
var on_floor: bool = false
var just_touched_floor: bool = false
var jump_alt: int = ALTERNATIVE.NORMAL
var can_play_animation: bool = true

## À redéfinir dans chaque enfant : les 8 suffixes d'animation dans l'ordre
## horaire en partant du Nord. Gardé par personnage car Mario et Luigi
## avaient deux conventions différentes dans les scripts d'origine —
## vérifiez que ça correspond bien aux noms de vos animations.
var sorted_direction: Array[StringName] = [&"N", &"NE", &"E", &"SE", &"S", &"SW", &"W", &"NW"]

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta

	_process_floor_transition()
	_process_fall_animation_alt()

func _process_floor_transition() -> void:
	just_touched_floor = false
	if on_floor != is_on_floor():
		on_floor = not on_floor
		if on_floor:
			touched_floor.emit()
			just_touched_floor = true

func _process_fall_animation_alt() -> void:
	if is_on_floor():
		return
	if velocity.y > center_fall_anim_rspeed:
		jump_alt = ALTERNATIVE.NORMAL
	elif velocity.y >= -center_fall_anim_rspeed:
		jump_alt = ALTERNATIVE.ALT
	else:
		jump_alt = ALTERNATIVE.ALT2
	if just_touched_floor:
		jump_alt = ALTERNATIVE.ALT3

func _process(_delta: float) -> void:
	if can_play_animation:
		animation_process()

## cur_direction : direction horizontale courante (typiquement
## Vector2(sign(velocity.x), sign(velocity.z))).
## is_walking : est-ce que le personnage avance activement (pas juste en
## train de décélérer / à l'arrêt).
func update_action_and_direction(cur_direction: Vector2, is_walking: bool) -> void:
	if not is_on_floor():
		state_action = ACTIONS.JUMP
	elif is_walking and cur_direction:
		state_action = ACTIONS.WALK
	else:
		state_action = ACTIONS.IDLE

	if not cur_direction:
		return  # pas d'input horizontal : on garde la dernière direction affichée

	# Note : on décale (+4) AVANT d'arrondir, ce qui garde la valeur non
	# négative sur tout l'intervalle. C'est ce qui évite le bug de l'ancien
	# calcul de Mario, où la division entière tronquait AVANT le décalage
	# et pouvait donner un index négatif près de l'Ouest (angle ±180°).
	var angle := cur_direction.angle()
	var octant := roundi(8.0 * angle / TAU + 4.0) % 8
	state_direction = sorted_direction[octant - 2]

func animation_process() -> void:
	if just_touched_floor:
		play_animation(ACTIONS.JUMP, state_direction, &"2")
	elif state_action == ACTIONS.WALK:
		play_animation(state_action, state_direction, &"")
	elif state_action == ACTIONS.IDLE:
		play_animation(state_action, state_direction, &"0")
	elif state_action == ACTIONS.JUMP:
		play_animation(state_action, state_direction, str(jump_alt))

func play_animation(action: StringName, _direction: StringName, _animation_alt: StringName) -> void:
	var parts: PackedStringArray = [String(action)]
	if not _direction.is_empty():
		parts.append(String(_direction))
	if not _animation_alt.is_empty():
		parts.append(String(_animation_alt))
	var composed_animation_name := "-".join(parts)

	if asprite3D.animation == StringName(composed_animation_name):
		return

	var old_frame := asprite3D.frame
	var old_progress := asprite3D.frame_progress
	asprite3D.play(StringName(composed_animation_name))
	if composed_animation_name.begins_with("walk") and asprite3D.animation.begins_with("walk"):
		asprite3D.set_frame_and_progress(old_frame, old_progress)

func try_jump() -> void:
	if is_on_floor():
		velocity.y = JUMP_VELOCITY
		jumpsfx.play()
