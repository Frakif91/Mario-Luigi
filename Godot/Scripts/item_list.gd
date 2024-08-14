extends Control

class_name InventoryItemList

signal item_have_been_choosed
signal move_finger(index)

@onready var item_template = preload("res://Godot/Nodes/item_template.tscn")
@onready var item_list_node = $"BagageBackgroundTexture/ScrollContainer/ItemList"
@onready var pointing_finger : TextureRect = $"BagageBackgroundTexture/Pointing-finger"
@onready var pointing_finger_og_x : float = pointing_finger.position.x
@onready var pointing_finger_og_y : float = pointing_finger.position.y

const TEXTURES = [preload("res://Godot/Assets/1UP Mushroom.tres"),
				  preload("res://Godot/Assets/mushroom.tres"),
				  preload("res://Godot/Assets/Sirop.tres"),
				  preload("res://Godot/Assets/Nut.tres"),
				  preload("res://Godot/Assets/shroom_default.tres"),
				  preload("res://Godot/Assets/bag.tres"),
				  preload("res://Godot/Assets/fresh herbs.tres")]

const NAMES = ["1UP Mushroom",
			   "Hyper Mushroom",
			   "Basic Sirop",
			   "Super Nut",
			   "Golden Mushroom",
			   "Coin Bag",
			   "Fresh Herbs"]

const QUANTITIES = [4,3,8,6,1,1,9]

#@onready var Items = Globals.ItemInventory.items
var default_shroom = Globals.itemQuantityEmpty
var health_shroom  = Globals.Inventory.Item_Quantity.new(Globals.Inventory.UniqueItem.new(load("res://Assets/HP.png"), "Health Shroom", "HAAAAA"),3)
var null_shroom    = Globals.Inventory.Item_Quantity.new(Globals.Inventory.UniqueItem.new(load("res://Godot/Assets/placeholder.tres"), "Null Shroom", "HEEEE"),69)

var Items = []
var Selectable_Items = []

var selected_item : int

# Called when the node enters the scene tree for the first time.
func _ready():
	item_have_been_choosed.connect(_item_choosed)
	move_finger.connect(_move_pf_to.bind(3))
	for index in range(7):
		Items.append(Globals.Inventory.Item_Quantity.new(
			Globals.Inventory.UniqueItem.new(TEXTURES[index],NAMES[index],"No description yet."),QUANTITIES[index]))
	item_list_init()

func item_list_init():
	for child in item_list_node.get_children():
		child.queue_free()		

	Selectable_Items.clear()
	#print(error_string(Globals.EatItemExample()))
	var i = 0
	for iq in Items:
		if iq.quantity <= 0: #Don't show empty item_quantity
			#Items.erase(iq) #Delete item quantity -> Cause problems
			continue
		Selectable_Items.append(iq)
		var item_object : ItemList_Object = item_template.instantiate()
		item_object.get_node(item_object.np_texture).texture = iq.item.texture
		item_object.get_node(item_object.np_name).text = iq.item.name
		item_object.get_node(item_object.np_quantity).text = "x" + str(iq.quantity)
		item_object.itemlist_index = i
		item_object.itemlist_choosed_signal = item_have_been_choosed
		item_object.pf_move_func = _move_pf_to
		item_object.move_finger = move_finger
		item_list_node.add_child(item_object.duplicate())
		i += 1

var fucking_test_var : int = 0
func _input(_event):
	if Globals.cur_action == Globals.ACTIONS_BLOCKS.ITEM:
		# if Input.is_action_just_pressed(&"TestButton1"):
		# 	pointing_finger_og_x = pointing_finger.position.x
		# 	return
	
		if Input.is_action_just_pressed(&"MenuDown"):
			fucking_test_var += 1
		if Input.is_action_just_pressed(&"MenuUp"):
			fucking_test_var -= 1

		if Input.is_action_just_pressed(&"MenuDown") or Input.is_action_just_pressed(&"MenuUp"):
			# if fucking_test_var >= item_list_node.get_child_count():
			# 	fucking_test_var = 0
			# elif fucking_test_var < 0:
			# 	fucking_test_var = item_list_node.get_child_count() - 1
			$"Select".play()
			fucking_test_var = fucking_test_var % item_list_node.get_child_count()
			item_list_node.get_child(fucking_test_var).grab_focus()
			item_list_node.get_child(fucking_test_var).focus_mode = FOCUS_ALL
			call_deferred(&"_move_pf_to",fucking_test_var)
		
		if Input.is_action_just_pressed(&"ui_accept"):
			if (Globals.RPG.combat_state == Globals.RPG.combat_turn.PLAYER_MENU):
				Selectable_Items[fucking_test_var].quantity -= 1
				Globals.eat_inventory_item.emit(Selectable_Items[fucking_test_var].item.texture,Selectable_Items[fucking_test_var])
				call_deferred(&"item_list_init")
		

var delta_sum = 0
@export var pf_indication_speed = 1.2
@export var pf_shake_power = 10
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if pf_taget_pos_y != 0:
		#pointing_finger.global_position.y = move_toward(pointing_finger.global_position.y,pf_taget_pos_y,_delta*1000)
		pointing_finger.global_position.y = pf_taget_pos_y
	delta_sum += _delta
	pointing_finger.position.x = pointing_finger_og_x + clampf(tan(deg_to_rad(delta_sum*360*pf_indication_speed))*pf_shake_power,-pf_shake_power,pf_shake_power+1.0)

func _item_choosed(item_index):
	var item = Selectable_Items[item_index]
	item.quantity -= 1

var pf_taget_pos_y : float

func _move_pf_to(item_index):
	print("Moving target")
	var child : Control = item_list_node.get_child(item_index)
	print_debug("Target n°",item_index," have gpos y :",child.global_position.y)
	pf_taget_pos_y = child.global_position.y

func item_power_application(item : Globals.Inventory.UniqueItem):
	match(item.name):
		"1UP Mushroom":
			pass
		"Hyper Mushroom":
			Globals.MARIO.hp = Globals.MARIO.hp + 60
		"Basic Sirop":
			Globals.MARIO.bp = Globals.MARIO.bp + 15
		


# const NAMES = ["1UP Mushroom",
# 			   "Hyper Mushroom",
# 			   "Basic Sirop",
# 			   "Super Nut",
# 			   "Golden Mushroom",
# 			   "Coin Bag",
# 			   "Fresh Herbs"]