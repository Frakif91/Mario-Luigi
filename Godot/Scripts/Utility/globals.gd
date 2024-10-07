extends Node

signal item_have_been_choosed
signal eat_inventory_item(tex : Texture2D, _item : Item_Quantity)
signal finish_eating
signal heal_mario(hp : int)
signal hurt_mario(damage : int)

#var chr_info = load("res://Godot/Scripts/CharacterInfo.gd")

#From Chooseblocks -> ["HAMMER","BROS.","FLEE","ITEM","JUMP"]
enum ACTIONS_BLOCKS {NONE = -1,HAMMER,JUMP,ITEM,FLEE,BROS}
var cur_action : ACTIONS_BLOCKS
var Bros : Dictionary # = {Mario = chr_info.create_character(chr_info.available.MARIO),
                      #    Luigi = chr_info.create_character(chr_info.available.LUIGI)}
var cur_brother : BrotherCB3
var RPG = RPG_System.new()
var trans_ready_time = 1

var is_itemlist_opened : bool = false
var chooseblocks_visible = true

const DIRECTION : Dictionary = {UP = &"N", DOWN = &"S", LEFT = &"W", RIGHT = &"E",
								UPLEFT = &"NW", UPRIGHT = &"NE", DOWNLEFT = &"SW", DOWNRIGHT = &"SE"}

class RPG_System:
    enum combat_turn {PLAYER_CHOOSING, PLAYER_MENU, PLAYER_SELECTING, PLAYER_ACTION, ENEMY_ACTION, INTERRUPTION}
    var combat_state: combat_turn = combat_turn.PLAYER_CHOOSING

func _ready():
    var mario_inst : Brother = CharacterDefaultStats.new().create_character(CharacterDefaultStats.available.MARIO)
    mario_inst.camera_position = Vector3(0.5,1.4,2.5)
    mario_inst.chooseblock_offset = Vector2(-0.5,-1)
    
    var luigi_inst : Brother = CharacterDefaultStats.new().create_character(CharacterDefaultStats.available.LUIGI)
    luigi_inst.camera_position = Vector3(0.5,1.4,2.5)
    luigi_inst.chooseblock_offset = Vector2(-1.25,0.6)

    Bros.merge({"Mario" = mario_inst, "Luigi" = luigi_inst})
    print("Bros :",Bros)

class Inventory:
    pass
    

var default_empty_texture = preload("res://Godot/Assets/placeholder.tres")
#var uniqueItemEmpty = UniqueItem.new(default_empty_texture, "No Item", "This item is empty")
#var itemQuantityEmpty = Item_Quantity.new(uniqueItemEmpty, -1);

func wait(seconds : float):
    await get_tree().create_timer(seconds).timeout