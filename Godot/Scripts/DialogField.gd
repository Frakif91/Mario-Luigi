class_name DialogField extends Resource

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
