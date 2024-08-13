extends PanelContainer

class_name ItemList_Object



@export var texture : Texture2D = preload("res://Godot/Assets/shroom_default.tres")
@export var fallback_texture : Texture2D = preload("res://Assets/HP.png")
@export var item_name : String = "Default Shroom"
@export var item_description : String = "A normal mushroom that recover 30 HP."
@export var item_quantity : int = 12
var itemlist_index : int
var itemlist_choosed_signal : Signal
var pf_move_func : Callable
var move_finger : Signal

@export_category("Can't have shit in Detroit")
@export_node_path("TextureRect") var np_texture
@export_node_path("Label") var np_name
@export_node_path("Label") var np_quantity

@onready var temp_texture : TextureRect = get_node(np_texture)
@onready var temp_name : Label = get_node(np_name)
@onready var temp_quantity : Label = get_node(np_quantity)

func update(_texture : Texture2D, _item_name : String, _item_quantity : int):
	if not (temp_texture or temp_name or temp_quantity):
		return ERR_FILE_UNRECOGNIZED
	if _texture:
		temp_texture.texture = _texture
	if _item_name:
		temp_name.text = _item_name
	if _item_quantity > 0:
		temp_quantity.text = "x" + str(_item_quantity)
	return OK

func _ready():
	if not (temp_texture or temp_name or temp_quantity):
		push_error("|||||||||||||| OBJECT NOT ABLE TO INIT")

func _item_selected():
	itemlist_choosed_signal.emit(itemlist_index)

	#update(texture,item_name,item_quantity)
	#item_object.get_node(^"./HSplitContainer/Item").texture = item.item.texture
		#item_object.get_node(^"./HSplitContainer/Name").text = item.item.name
		#item_object.get_node(^"./HSplitContainer/Number").text = "x" + str(item.quantity)


func _on_button_pressed():
	itemlist_choosed_signal.emit(itemlist_index)


func _on_button_mouse_entered():
	move_finger.emit(itemlist_index)
	print_debug("Emmited")
	#pf_move_func.call(itemlist_index)
