class_name CamFollow extends Camera3D

@export var speed : float = 10
@export var follow_offset : Vector3
@export var script_overrite : bool = false
var target_position
var old_position

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if is_multiplayer_authority():
		current = true
	target_position = get_parent_node_3d().global_position + follow_offset
	old_position = target_position


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	if not script_overrite:
		var parent = get_parent_node_3d()
		if parent:
			target_position = parent.global_position + follow_offset
	old_position = lerp(old_position, target_position, delta * speed)
	global_position = old_position*get_parent_node_3d().scale

