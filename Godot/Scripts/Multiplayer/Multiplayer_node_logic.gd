class_name MultiplayerManager extends Node3D

var multiplayer_peer = ENetMultiplayerPeer.new()

const PORT = 1337

var connected_peer_ids = []
var local_player_character
@export var player_scene : PackedScene

@export var is_online : bool = true
@export var max_player : int = 10
@export var is_host : bool = false

@export_node_path("RichTextLabel") var textchat_np : NodePath = ^"UI/Chat/PanelContainer/VSplitContainer/MarginContainer/TextChat"
@export_node_path("LineEdit") var sendchat_np : NodePath = ^"UI/Chat/PanelContainer/VSplitContainer/SendChat"

@onready var textchat : RichTextLabel = get_node_or_null(textchat_np)
@onready var sendchat : LineEdit = get_node_or_null(sendchat_np)

func _on_host_launch(port : int, _username : String):
	multiplayer_peer.create_server(port)
	multiplayer.multiplayer_peer = multiplayer_peer	
	add_player_character(1)
	
	multiplayer_peer.peer_connected.connect(
		func(new_peer_id):
			await get_tree().create_timer(1).timeout
			rpc("add_newly_connected_player_character", new_peer_id) #Warn everyone someone is connecting to add the player to Client Interface
			rpc_id(new_peer_id, "add_previously_connected_player_characters", connected_peer_ids) #Add to the new player every-already-connected player to new client interface
			add_player_character(new_peer_id)
	)

func _on_player_joining(ip : String, port : int, _username : String):
	multiplayer_peer.create_client(ip, port)
	multiplayer.multiplayer_peer = multiplayer_peer

func add_player_character(peer_id):
	connected_peer_ids.append(peer_id)
	var player_character = player_scene.instantiate()
	player_character.set_multiplayer_authority(peer_id)
	add_child(player_character)
	if peer_id == multiplayer.get_unique_id():
		local_player_character = player_character

@rpc("authority", "call_local", "reliable")
func add_newly_connected_player_character(new_peer_id):
	add_player_character(new_peer_id)
	
@rpc("authority", "call_remote", "reliable")
func add_previously_connected_player_characters(peer_ids):
	for peer_id in peer_ids:
		add_player_character(peer_id)

func _ready() -> void:
	sendchat.text_submitted.connect(_on_message_input_text_submitted)

func _on_message_input_text_submitted(new_text):
	if local_player_character:
		rpc("display_message",new_text)
	else:
		if textchat:
			textchat.push_color(Color(1,0.3,0.3))
			textchat.append_text("\nYou have to be connected to a server to do that !")
			textchat.push_color(Color(1,1,1))
		else:
			push_error("No fucking textchat")
	sendchat.text = ""
	sendchat.release_focus()

@rpc("any_peer", "call_local", "reliable", 1)
func display_message(message : String):
	textchat.append_text("\n<[b]"+str(multiplayer.get_remote_sender_id())+"[/b]> " + message)
	textchat.push_normal()


# var peer : ENetMultiplayerPeer = ENetMultiplayerPeer.new()
# @export var player_scene : PackedScene

# func _on_host_launch(port : int, _username : String):
# 	print_debug("Creating Server on port : "+str(port))
# 	peer.create_server(port)
# 	multiplayer.multiplayer_peer = peer
# 	multiplayer.peer_connected.connect(_add_player)
# 	_add_player()

# func _add_player(id = 1):
# 	print_debug("Adding Player with ID : "+str(id))
# 	var player = player_scene.instantiate()
# 	player.name = str(id)
# 	player.set_indexed(^"./Info:username","Dumbass")
# 	call_deferred(&"add_child",player)

# func _on_player_joining(ip : String, port : int, _username : String):
	
# 	var connection_result = peer.create_client(ip,port)
# 	if connection_result != OK:
# 		push_error("Cannot connect to server : " + error_string(connection_result))
# 	if connection_result == ERR_ALREADY_IN_USE:
# 		push_warning("Closing connection due to be already connected")
# 		peer.close()
# 		connection_result = peer.create_client(ip,port)
# 	multiplayer.multiplayer_peer = peer

signal info_received(uid : Multiplayer_Info.MultiplayerClientUID)

@rpc("any_peer", "call_remote" ,"reliable")
func _ask_info(peer_id : int):
	rpc_id(peer_id, "_send_info")

@rpc("any_peer", "call_remote", "reliable")
func _send_info(peer_id : int):
	if peer_id != multiplayer.get_unique_id():
		rpc_id(peer_id, "_send_info", self)

@rpc("any_peer", "call_remote", "reliable")
func _get_info(peer_id : int, uid : Multiplayer_Info.MultiplayerClientUID):
	if peer_id != multiplayer.get_unique_id():
		info_received.emit(uid)


func ask_user_info(peer_id: int):
	if multiplayer.get_peers().has(peer_id):
		_ask_info(peer_id)
		var info = await info_received
		if info:
			return info
		else:
			return null
	else:
		return null