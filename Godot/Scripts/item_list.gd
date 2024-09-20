extends Control

class_name InventoryItemList

signal item_have_been_choosed
signal move_finger(index)

@onready var item_template = preload("res://Godot/Nodes/item_template.tscn")
@onready var item_list_node = $"BagageBackgroundTexture/ScrollContainer/ItemList"
@onready var pointing_finger : TextureRect = $"BagageBackgroundTexture/Pointing-finger"
@onready var pointing_finger_og_x : float = pointing_finger.position.x
@onready var pointing_finger_og_y : float = pointing_finger.position.y
@export var pf_offset_y = 5

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

const DESCRIPTIONS = ["Revives a down brother with half of his HP.",
					  "Heal upto 60HP with this perfectly grown mushroom.",
					  "Gain up to 15BP with this basic sirop.",
					  "You know what it mean.",
					  "A Golden mushroom, let you regain all your HP.",
					  "a Bag of coins, this does nothing actually.",
					  "Those fresh herbs can cure basicly any condition."]

const QUANTITIES = [4,3,8,6,1,1,9]

#@onready var Items = Globals.ItemInventory.items
var default_shroom = preload("res://Godot/Assets/UniqueItem/defaultItemQuantity.tres")
var health_shroom  = preload("res://Godot/Assets/UniqueItem/health_shroom.tres")
var null_shroom    = preload("res://Godot/Assets/UniqueItem/null_shroom.tres")

var sounds = [preload("res://Assets/Sound/SE_BTL_1UP.wav"),preload("res://Assets/SFX/Mario_&_Luigi_DT_Heal.ogg"),preload("res://Assets/SFX/Mario_&_Luigi_SS_&_BM_Heal.ogg")]

var Items = []
var Selectable_Items = []

var selected_item : int
var item_index : int = 0 #same thing as selected_item but used this time

var description_label_size
var wait_between_reshow = 1.5

@onready var audio_player : AudioStreamPlayer = AudioStreamPlayer.new()

# Called when the node enters the scene tree for the first time.
func _ready():
	add_child(audio_player)
	item_have_been_choosed.connect(_item_choosed)
	move_finger.connect(_move_pf_to.bind(3))
	for index in range(7):
		Items.append(Item_Quantity.new(
			UniqueItem.create(TEXTURES[index],NAMES[index],DESCRIPTIONS[index]),QUANTITIES[index]))
	%Description.text = " " + DESCRIPTIONS[0]
	description_label_size = %Description.get_end()
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
		item_object.tooltip_text = iq.item.description
		item_object.itemlist_index = i
		item_object.itemlist_choosed_signal = item_have_been_choosed
		item_object.pf_move_func = _move_pf_to
		item_object.move_finger = move_finger
		item_list_node.add_child(item_object.duplicate())
		i += 1

func _input(_event):
	if Globals.cur_action == Globals.ACTIONS_BLOCKS.ITEM:
		# if Input.is_action_just_pressed(&"TestButton1"):
		# 	pointing_finger_og_x = pointing_finger.position.x
		# 	return
	
		if Input.is_action_just_pressed(&"MenuDown"):
			item_index += 1
		if Input.is_action_just_pressed(&"MenuUp"):
			item_index -= 1

		if Input.is_action_just_pressed(&"MenuDown") or Input.is_action_just_pressed(&"MenuUp"):
			# if item_index >= item_list_node.get_child_count():
			# 	item_index = 0
			# elif item_index < 0:
			# 	item_index = item_list_node.get_child_count() - 1
			$"Select".play()
			item_index = item_index % item_list_node.get_child_count()
			item_list_node.get_child(item_index).set_focus_mode(FOCUS_ALL)
			item_list_node.get_child(item_index).grab_focus()
			await Globals.wait(0.01)
			%Description.text = " " + Selectable_Items[item_index].item.description
			call_deferred(&"_move_pf_to",item_index)
		
		if Input.is_action_just_pressed(Globals.cur_brother.bro.action_button):
			if (Globals.RPG.combat_state == Globals.RPG.combat_turn.PLAYER_MENU):
				Selectable_Items[item_index].quantity -= 1
				Globals.eat_inventory_item.emit(Selectable_Items[item_index].item.texture,Selectable_Items[item_index])
				call_deferred(&"item_list_init")
		

var delta_sum = 0
@export var pf_indication_speed = 1.2
@export var pf_shake_power = 10
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if pf_taget_pos_y != 0:
		#pointing_finger.global_position.y = move_toward(pointing_finger.global_position.y,pf_taget_pos_y,_delta*1000)
		pointing_finger.global_position.y = pf_taget_pos_y + pf_offset_y
	delta_sum += _delta
	pointing_finger.position.x = pointing_finger_og_x + clampf(tan(deg_to_rad(delta_sum*360*pf_indication_speed))*pf_shake_power,-pf_shake_power,pf_shake_power+1.0)

func _item_choosed(_item_index):
	var item = Selectable_Items[_item_index]
	item.quantity -= 1

var pf_taget_pos_y : float

func _move_pf_to(_item_index):
	#print("Moving target")
	var child : Control = item_list_node.get_child(_item_index)
	print_debug("Target n°",_item_index," have gpos y :",child.global_position.y)
	pf_taget_pos_y = child.global_position.y

#var damage_instance = preload("res://Godot/Scripts/Damage_Anouncer.gd")
var damage_instance = preload("res://Godot/Nodes/damage_display.tscn")

func show_heal(heal: int, posin3d: Vector3, damage_type: int):
	print("SHOWED")
	var di: DamageAnnouncer = damage_instance.instantiate()
	di.create(posin3d, heal, damage_type)
	add_child(di)
	di.show()
	di.showup()


func _play_audio(audio_file : AudioStream):
	audio_player.stream = audio_file
	audio_player.play()

func item_power_application(item : UniqueItem):
	match(item.name):
		"1UP Mushroom":
			_play_audio(sounds[0])
			show_heal(0,Globals.cur_brother.position + Vector3(0.2,0,0),DamageAnouncerTexture.BackGroundTexture.HEAL)
		"Hyper Mushroom":
			_play_audio(sounds[1])
			show_heal(60,Globals.cur_brother.position + Vector3(0,0,0),DamageAnouncerTexture.BackGroundTexture.HEAL)
			Globals.cur_brother.bro.hp = Globals.cur_brother.bro.hp + 60
		"Basic Sirop":
			_play_audio(sounds[2])
			show_heal(15,Globals.cur_brother.position + Vector3(0.2,0,0),DamageAnouncerTexture.BackGroundTexture.HEAL)
			Globals.cur_brother.bro.bp = Globals.cur_brother.bro.bp + 15
		


# const NAMES = ["1UP Mushroom",
# 			   "Hyper Mushroom",
# 			   "Basic Sirop",
# 			   "Super Nut",
# 			   "Golden Mushroom",
# 			   "Coin Bag",
# 			   "Fresh Herbs"]
