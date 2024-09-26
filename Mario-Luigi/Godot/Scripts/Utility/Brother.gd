class_name Brother extends Resource
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