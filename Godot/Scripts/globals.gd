extends Node

signal item_have_been_choosed
signal eat_inventory_item(tex : Texture2D, _item : Globals.Inventory.Item_Quantity)
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

class RPG_System:
    enum combat_turn {PLAYER_CHOOSING, PLAYER_MENU, PLAYER_SELECTING, PLAYER_ACTION}
    var combat_state: combat_turn = combat_turn.PLAYER_CHOOSING

func _ready():
    var mario_inst = CharacterDefaultStats.new().create_character(CharacterDefaultStats.available.MARIO)
    mario_inst.camera_position = Vector3(0.5,1.4,2.5)
    mario_inst.chooseblock_offset = Vector2(-0.5,-1)
    
    var luigi_inst = CharacterDefaultStats.new().create_character(CharacterDefaultStats.available.LUIGI)
    luigi_inst.camera_position = Vector3(0.5,1.4,2.5)
    luigi_inst.chooseblock_offset = Vector2(-1.25,0.6)

    Bros.merge({"Mario" = mario_inst, "Luigi" = luigi_inst})
    print("Bros :",Bros)

class Inventory:
    class UniqueItem:
        var texture : Texture2D;
        var name : StringName;
        var description : String;

        ## Create an Unique Item that will represent a useful item in combat.
        ## It consist of a **texture**, a **name** and a **description**, which are `Texture2D`, `String` and `String` respectly
        func _init(_texture : Texture, _name : StringName, _description : String):
            
            if not _texture:
                _texture = load("res://Godot/Assets/shroom_default.tres")
            if not _name:
                _name = "Default Shroom"
            if not _description:
                _description = "An normal mushroom with the texture of a golden one, gain 30 HP on use."

            texture = _texture;
            name = _name;
            description = _description;

    class Item_Quantity:
        var item : UniqueItem;
        var quantity : int;

        func _init(_item : UniqueItem, _quantity : int = 0):
            self.item = _item
            self.quantity = _quantity
    

var default_empty_texture = preload("res://Godot/Assets/placeholder.tres")
var uniqueItemEmpty = Inventory.UniqueItem.new(default_empty_texture, "No Item", "This item is empty")
var itemQuantityEmpty = Inventory.Item_Quantity.new(uniqueItemEmpty, -1);

class Brother:
    @export_category("Character Stats")
    @export var node_path : NodePath
    @export var character_name : StringName = "Mario"
    @export var hp : int = 21:
        set(new_hp):
            hp = clampi(new_hp,0,max_hp)
        get:
            return hp
    @export var bp : int = 18
    @export var max_hp : int = 36
    @export var max_bp : int = 24
    @export var attack : int = 13
    @export var defense : int = 15
    @export var speed : int = 10
    @export var level : int = 5
    @export var xp : int = 300
    @export var xp_to_next_level : int = 80

    @export_category("Other")
    @export var overrite_animation = false
    @export var can_jump = true
    @export var chooseblock_offset : Vector2
    @export var camera_position : Vector3
    @export var og_position : Vector3
    @export var action_button : StringName = &"MarioButton"

    func _init(name,_max_hp,_max_bp):
        character_name = name
        max_hp = _max_hp
        max_bp = _max_bp
    
    enum states {IDLE,TIRED,KO}

    var cur_state : states

    func update_state() -> states:
        if hp <= 0: cur_state = states.KO
        elif hp <= ceili(max_hp*0.3): cur_state = states.TIRED
        else: cur_state = states.IDLE
        return cur_state


func wait(seconds : float):
    await get_tree().create_timer(seconds).timeout