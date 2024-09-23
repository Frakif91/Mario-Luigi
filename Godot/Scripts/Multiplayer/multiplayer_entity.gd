class_name MultiplayerEntity extends Node

@onready var info = $"Info"
@onready var mario = $"Mario"
@onready var luigi = $"Luigi"

func _ready():
	name = str(multiplayer.multiplayer_peer.get_unique_id())
	$"Mario/Label3D".text = str(name)
	$"Mario".did_move.connect(remote_set_position)

# 		global_position += direction.normalized()
# 		rpc("remote_set_position", global_position)
		
@rpc("any_peer","unreliable")
func remote_set_position(authority_position):
	$"Mario".global_position = authority_position

	
# @rpc("any_peer", "call_local", "reliable", 1)
# func clicked_by_player():
# 	$Message.text = str(multiplayer.get_remote_sender_id()) + " clicked on me!"

# func _on_mouse_click_area_input_event(camera, event, position, normal, shape_idx):
# 	if event is InputEventMouseButton:
# 		rpc("clicked_by_player")


# @onready var info = $"Info"

# func _enter_tree() -> void:
# 	set_multiplayer_authority(name.to_int())

# # Called when the node enters the scene tree for the first time.
# func _ready() -> void:
# 	set_multiplayer_authority(name.to_int())
# 	if is_multiplayer_authority():
# 		$"Mario/Camera3D".current = true


# # Called every frame. 'delta' is the elapsed time since the previous frame.
# func _process(delta: float) -> void:
# 	pass

# @rpc()
# func ask_peer_data(id : int, data : Variant) -> String:
# 	if multiplayer.get_remote_sender_id() != 0:
# 		if multiplayer.multiplayer_peer.get_unique_id() == id:
# 			pass
# 			#rpc_id(multiplayer.get_remote_sender_id()
# 	return "None"

# @rpc("any_peer")
# func give_var(id, x): 
# 	rset_id(id, x, global[x])