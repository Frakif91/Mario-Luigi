class_name DialogField extends Resource
@export var dialog : Array[Dialog]

class Dialog extends Resource:
    @export var e = 0

class DialogSound extends Dialog:
    @export var sfx : AudioStream

class DialogText extends Dialog:
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

class DialogCamera extends Dialog:
    @export_enum("Static","MiddleCharacters") var camera_type
