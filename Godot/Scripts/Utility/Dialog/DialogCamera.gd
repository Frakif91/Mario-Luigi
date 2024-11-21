class_name DialogCamera extends Dialog

@export_enum("NPC","Player (Mario)","Between Player & NPC","Custom value") var camera_target
@export var custom_target_position : Vector2
@export var action_time : float = 5.0
@export var camera_trans : Tween.TransitionType
@export var camera_ease : Tween.EaseType
@export var finish_action_first : bool = false

func execute(tree : SceneTree, player : MarioOW_Movement, npc : NPC):
    var camera : CamFollow = (tree.get_camera_3d() as CamFollow)
    
    match(camera_target):
        "NPC":
            pass
        "Player (Mario)":
            pass
        "Between Player & NPC":
            pass
        "Custom value":
            camera.script_overrite = true
            var pos_tween = (get_tree().create_tween() as Tween)
            pos_tween.set_ease(camera_ease)
            pos_tween.set_trans(camera_trans)
            pos_tween.tween_property(camera,"follow_offset",custom_target_position,action_time)
            if finish_action_first:
                await pos_tween.finished