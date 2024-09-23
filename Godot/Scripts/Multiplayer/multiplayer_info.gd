class_name Multiplayer_Info extends Node

@export var username : String = "No Username"
@export var ip_adress : String = "no"
@export var multi_authority : int

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	multi_authority = get_multiplayer_authority()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
