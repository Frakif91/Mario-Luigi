extends Control

@onready var mariopanel : TextureNumber = $"MarioUI/HP"
@onready var luigipanel : TextureNumber = $"LuigiUI/HP"
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if Globals.Bros.has("Mario"):
		mariopanel.value = (Globals.Bros.get("Mario") as Brother).hp
	if Globals.Bros.has("Luigi"):
		mariopanel.value = (Globals.Bros.get("Luigi") as Brother).hp
