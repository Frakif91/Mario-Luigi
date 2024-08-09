extends Control

class UniqueItem:
	var texture : Texture2D
	var name : StringName
	var description : String

	func _init(_texture : Texture2D, _name : String, _description : String):
		if !_texture:
			_texture = preload("res://Godot/Assets/shroom_default.tres")
		if _name.is_empty():
			_name = "Default Shroom"
		if _description.is_empty():
			_description = "An normal mushroom with the texture of a golden one, gain 30 HP on use."
		
		self.texture = _texture
		self.name = _name
		self.description = _description





@onready var item_list_node = $"BagageBackgroundTexture/ItemList"

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass
