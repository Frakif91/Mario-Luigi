class_name Teleporter extends Area3D

@export_subgroup("Target","target")
@export var target_reload_cur_scene : bool = false
@export_file("*.tscn") var target_scene : String
@export var target_pos : Vector3
@export var target_direction = Globals.DIRECTION.LEFT
@export_subgroup("Transition")
@export var transition_type : Transitions.TransitionType
@export var transition_loading_screen : bool = true
@export var time_before_transition : float = 0.0
@export_subgroup("Effects")
@export_node_path("AudioStreamPlayer","AudioStreamPlayer3D") var sound_np
@export_range(0.0,1.0,0.05) var volume_linear : float = 0.5
@export_node_path("CamFollow") var camera_np

@onready var camera : CamFollow

func _ready():
    if not camera_np.is_empty():
        camera = get_node(camera_np)
    else:
        push_error("Camera not init")

    var success = false
    for child_index in get_child_count(false):
        var child = get_child(child_index)
        if child is CollisionShape3D:
            body_entered.connect(body_enter)
            success = true
    assert(success,"Did not found correct CollisionShape3D")

func _input(_event: InputEvent) -> void:
    if Input.is_action_pressed(&"Test2"):
        camera.script_overrite = not camera.script_overrite


func body_enter(body):
    print_debug("Body entered",body)
    if body is MarioOW_Movement:
        if get_node_or_null(sound_np):
            get_node(sound_np).play()

        var do_change_cam = not camera.script_overrite
        if do_change_cam:
            camera.script_overrite = true

        await Globals.wait(0.001 + time_before_transition)
        if target_reload_cur_scene:
            await Transitions.start_loading("", Transitions.TransitionType.CIRCULAR, get_tree(), transition_loading_screen)
        else:
            if target_scene:
                await Transitions.start_loading(target_scene, Transitions.TransitionType.CIRCULAR, get_tree(), transition_loading_screen)
        if do_change_cam:
            camera.script_overrite = false