extends PanelContainer

class_name ItemList_Object

@export var texture : Texture2D = preload("res://Godot/Assets/shroom_default.tres")
@export var fallback_texture : Texture2D = preload("res://Assets/HP.png")
@export var item_name : String = "Default Shroom"
@export var item_description : String = "A normal mushroom that recover 30 HP."
@export var item_quantity : int = 12

@onready var temp_texture : TextureRect = %Item
@onready var temp_name : Label = %Name
@onready var temp_quantity : Label = %Number

func _ready():
    if texture:
        temp_texture.texture = texture
    if item_name:
        temp_name.text = name
    if item_quantity > 0:
        temp_quantity.text = "x" + (item_quantity as String)