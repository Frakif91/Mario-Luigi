class DialogCamera extends Dialog:
    @export_enum("Target : NPC","Target : Player","MiddleCharacters","Target : Custom") var camera_type
    @export var custom_target_position : Vector2
    
