class_name PlayerSaveData extends Resource

@export var save_sys_version : int = 1024 #Version : 1.0.0
@export var online_username : String = "Undefined"
@export var money : int
@export var playtime : int
@export var playable_character : Array[Brother]
@export var inventory_items : Array[Item_Quantity]
@export var story_var : int
@export_file("*.tscn") var cur_world : String
@export var cur_coordinate : Vector3

var save_slot_1 = "user://save1.dat"

signal game_saved()

func _save_game(_args : Dictionary):
    var fw = FileAccess.open(save_slot_1,FileAccess.WRITE)

    if not fw: #If FileAcces.open() crashed
        push_error("PSD Save Handler : " + error_string(FileAccess.get_open_error()))

    fw.flush()

    fw.store_var(online_username,true)
    fw.store_var(money,true)
    fw.store_var(playtime,true)
    fw.store_var(playable_character,true)
    fw.store_var(inventory_items,true)
    fw.store_var(story_var,true)
    
    if _args:
        fw.store_var(_args,true)

    fw.close()

func _load_game():
    if FileAccess.file_exists(save_slot_1):
        var fw = FileAccess.open(save_slot_1,FileAccess.WRITE)
        
        if not fw: #If FileAcces.open() crashed
            push_error("PSD Save Handler : " + error_string(FileAccess.get_open_error()))

        var file_version = fw.get_var()

        assert(file_version == save_sys_version,"Save File Version is different than current Save System (Cur "+str(save_sys_version)+" <-> File "+str(file_version)+")")

        online_username    = fw.get_var(true)
        money              = fw.get_var(true)
        playtime           = fw.get_var(true)
        playable_character = fw.get_var(true)
        inventory_items    = fw.get_var(true)
        story_var          = fw.get_var(true)
        
        var args           = fw.get_var(true)

        fw.close()
        if args:
            return args
        else:
            return null
    else:
        push_error("Save file doesn't exist, create one")