class_name EnemyInfo extends Resource

@export var enemy_name = "Goomba"
@export var max_hp = 20
var hp
@export var level = 5
@export var spritesheet : SpriteFrames
#@export var movesets : Array[Callable]
@export var is_stompable : bool = true
@export var animation_dictionary = {"idle" = "idle", "rush" = "rush"}