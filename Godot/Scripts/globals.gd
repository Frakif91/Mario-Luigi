extends Node

signal item_have_been_choosed
signal eat_inventory_item(tex : Texture2D, _item : Globals.Inventory.Item_Quantity)
signal finish_eating
signal heal_mario(hp : int)
signal hurt_mario(damage : int)

#From Chooseblocks -> ["HAMMER","BROS.","FLEE","ITEM","JUMP"]
enum ACTIONS_BLOCKS {NONE = -1,HAMMER,JUMP,ITEM,FLEE,BROS}
var cur_action : ACTIONS_BLOCKS
var Bros : Dictionary = {}
var cur_brother : BrotherCB3
var RPG = RPG_System.new()
var trans_ready_time = 1

var is_itemlist_opened : bool = false
var chooseblocks_visible = true

class RPG_System:
    enum combat_turn {PLAYER_CHOOSING, PLAYER_MENU, PLAYER_SELECTING, PLAYER_ACTION}
    var combat_state: combat_turn = combat_turn.PLAYER_CHOOSING

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

func wait(seconds : float):
    await get_tree().create_timer(seconds).timeout