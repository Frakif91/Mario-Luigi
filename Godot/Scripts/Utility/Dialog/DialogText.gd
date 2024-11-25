class_name DialogText extends Dialog

@export_category("Dialog Options")
@export var text : String = ""
@export var sfx : AudioStream
@export var each_n_letters : int = 1
@export var text_size : int = 32
@export var text_delay : float = 0
@export var text_alignment : HorizontalAlignment
@export var text_effect : RichTextEffect
@export var skipable : bool = false
@export_category("Textbox Options")
@export var textbox_size : Vector2 = Vector2(300,100)

func execute(tree : SceneTree, player : MarioOW_Movement, npc : NPC):
    npc.textbox._show_dialog(self)
