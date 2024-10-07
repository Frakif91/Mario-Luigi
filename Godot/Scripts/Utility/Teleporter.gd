class_name Teleporter extends Area3D

@export_subgroup("Target","target")
@export_file("*.tscn") var target_scene : String
@export var target_pos : Vector3
@export var target_direction = Globals.DIRECTION.LEFT
@export_subgroup("Transition")
@export var transition_type : Transitions.TransitionType

func _ready():
    var success = false
    for child_index in get_child_count(false):
        var child = get_child(child_index)
        if child is CollisionShape3D:
            body_entered.connect(body_enter)
            success = true
    assert(success,"Did not found correct CollisionShape3D")

func body_enter(body):
    print_debug("Body entered",body)
    if body is MarioOW_Movement:
        if target_scene:
            Transitions.start_loading(target_scene, Transitions.TransitionType.CIRCULAR, get_tree())