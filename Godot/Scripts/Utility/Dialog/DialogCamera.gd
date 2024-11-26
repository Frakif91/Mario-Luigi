class_name DialogCamera extends Dialog

@export_enum("NPC","Player (Mario)","Between Player & NPC","Custom value") var camera_target
@export var activate_camera_dialog : bool = true
@export var custom_target_position : Vector3
@export var action_time : float = 5.0
@export var camera_trans : Tween.TransitionType
@export var camera_ease : Tween.EaseType
@export var finish_action_first : bool = false
@export var zoom : float = 1
var cur_zoom = Vector3(0,1,1.5)

func execute(tree : SceneTree, player : MarioOW_Movement, npc : NPC):
    var camera : CamFollow = (tree.get_camera_3d() as CamFollow)
    if activate_camera_dialog:
        var target_position : Vector3
        match(camera_target):
            "NPC":
                target_position = npc.position + cur_zoom/zoom
            "Player (Mario)":
                target_position = player.position + cur_zoom/zoom
            "Between Player & NPC":
                target_position = (player.position - npc.position)/2 + player.position + cur_zoom/zoom
            "Custom value":
                target_position = custom_target_position
                
        camera.script_overrite = true
        var pos_tween = (tree.create_tween() as Tween)
        pos_tween.set_ease(camera_ease)
        pos_tween.set_trans(camera_trans)
        pos_tween.tween_property(camera,"follow_offset",target_position,action_time)
        if finish_action_first:
            await pos_tween.finished
    else:
        camera.script_overrite = false