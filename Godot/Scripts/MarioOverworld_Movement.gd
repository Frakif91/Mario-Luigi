class_name MarioOW_Movement
extends OWCharacterMovement

## Leader contrôlé par le joueur. Enregistre une trace (breadcrumb trail)
## que Luigi suit à distance. Quand la trace est pleine — c'est-à-dire que
## Luigi n'arrive pas à consommer les points assez vite, typiquement parce
## qu'il est physiquement coincé quelque part — Mario est retenu et ne peut
## plus s'éloigner davantage, comme une laisse.

signal did_move(position: Vector3)
signal start_move
signal stop_move

@export var walk_sound_waittime: float = 12.0 / 20.0 / 2.0
@export_node_path("LuigiOW_Movement") var luigi_np: NodePath

## Distance (en unités du monde) entre deux points enregistrés dans la trace.
@export var trail_sample_distance: float = 0.35
## Nombre max de points en attente. La longueur de la laisse, en unités du
## monde, vaut environ trail_max_length * trail_sample_distance.
@export var trail_max_length: int = 20

@onready var luigi: LuigiOW_Movement = get_node_or_null(luigi_np)
@onready var right_foot: AudioStreamPlayer = $"RightFoot"
@onready var right_foot_2: AudioStreamPlayer = $"RightFoot2"
@onready var footstep_timer: Timer = $"Timer"

## Trace de déplacement, du plus ancien (index 0, la cible actuelle de
## Luigi) au plus récent. Possédée par Mario, lue et vidée par Luigi.
var trail: Array[Vector3] = []

var cur_right_foot: bool = false
var is_moving: bool = false

func _ready() -> void:
	sorted_direction = [&"N", &"NE", &"E", &"SE", &"S", &"SW", &"W", &"NW"]

	footstep_timer.timeout.connect(_walk_sound)
	footstep_timer.autostart = false
	footstep_timer.one_shot = true
	stop_move.connect(footstep_timer.stop)
	start_move.connect(func(): footstep_timer.start(walk_sound_waittime / 2.0))

	if luigi == null:
		push_warning("MarioOW_Movement (%s) : Luigi introuvable via luigi_np, la laisse ne fonctionnera pas." % [name])

func _walk_sound() -> void:
	(right_foot if cur_right_foot else right_foot_2).play()
	cur_right_foot = not cur_right_foot
	footstep_timer.start(walk_sound_waittime)

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	_update_footstep_pause()

	if Input.is_action_just_pressed(&"Jump"):
		try_jump()

	# Comme avant : input relatif à l'orientation du personnage.
	var input_dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()
	_enforce_leash()
	_handle_block_bumps()

	var currently_moving := velocity.x != 0.0 or velocity.z != 0.0
	if currently_moving and not is_moving:
		is_moving = true
		start_move.emit()
	elif not currently_moving and is_moving:
		is_moving = false
		stop_move.emit()

	if currently_moving:
		_record_trail_point()
		did_move.emit(global_position)

	update_action_and_direction(Vector2(sign(velocity.x), sign(velocity.z)), currently_moving)

func _update_footstep_pause() -> void:
	if footstep_timer.time_left <= 0:
		return
	if not is_on_floor():
		footstep_timer.paused = true
	elif footstep_timer.paused:
		footstep_timer.paused = false
		footstep_timer.start(walk_sound_waittime / 2.0)

func _handle_block_bumps() -> void:
	if not is_on_ceiling_only():
		return
	for i in get_slide_collision_count():
		var collider := get_slide_collision(i).get_collider()
		if is_instance_of(collider, OW_Block):
			(collider as OW_Block).block_hit.emit()

## true dès que la trace est pleine : Luigi est trop loin derrière (bloqué,
## ou juste en retard) pour qu'on le laisse consommer des points plus vite
## qu'on en ajoute.
func _is_leashed() -> bool:
	return trail.size() >= trail_max_length

func _record_trail_point() -> void:
	if trail.size() >= trail_max_length:
		return
	if trail.is_empty() or global_position.distance_to(trail[-1]) >= trail_sample_distance:
		trail.append(global_position)

## Si la laisse est tendue, on ramène Mario dans un petit rayon autour du
## dernier point de trace au lieu de le figer complètement : il peut
## toujours bouger latéralement ou revenir vers Luigi, mais pas s'éloigner
## davantage. Vector3.limit_length garde la direction du déplacement tout
## en plafonnant sa longueur — pas besoin de logique de blocage plus lourde.
func _enforce_leash() -> void:
	if not _is_leashed():
		return

	var anchor: Vector3 = trail[-1] if not trail.is_empty() else global_position
	if luigi != null and trail.is_empty():
		anchor = luigi.global_position

	var offset := global_position - anchor
	if offset.length() > trail_sample_distance:
		global_position = anchor + offset.limit_length(trail_sample_distance)
