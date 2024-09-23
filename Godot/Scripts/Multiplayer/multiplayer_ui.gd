extends Control

@export_node_path("MultiplayerManager") var multi_manager_np : NodePath
@onready var multi_manager : MultiplayerManager = get_node_or_null(multi_manager_np)

@onready var ip_adress : String = "NO IP"
@onready var port : int = 0
@onready var username : String = "No Username"
@onready var player_list = $"PlayerList/MarginContainer/VBoxContainer"
@onready var info_label = $"MarginContainer/Control/Panel/MarginContainer/VBoxContainer/Label3"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass

func _on_host_button_pressed() -> void:
	ip_adress = $"MarginContainer/Control/Panel/MarginContainer/VBoxContainer/HBoxContainer/IP4".text
	port = int($"MarginContainer/Control/Panel/MarginContainer/VBoxContainer/HBoxContainer/Port".text)
	username = $"MarginContainer/Control/Panel/MarginContainer/VBoxContainer/Username".text
	
	# $NetworkInfo/NetworkSideDisplay.text = "Server"
	# $Menu.visible = false

	multi_manager._on_host_launch(port,username)


func _on_join_button_pressed() -> void:
	ip_adress = $"MarginContainer/Control/Panel/MarginContainer/VBoxContainer/HBoxContainer/IP4".text
	port = int($"MarginContainer/Control/Panel/MarginContainer/VBoxContainer/HBoxContainer/Port".text)
	username = $"MarginContainer/Control/Panel/MarginContainer/VBoxContainer/Username".text
	multi_manager._on_player_joining(ip_adress,port,username)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if multiplayer.has_multiplayer_peer():
		var connection_status = multiplayer.multiplayer_peer.get_connection_status()
		if connection_status == multiplayer.multiplayer_peer.ConnectionStatus.CONNECTION_CONNECTED:
			info_label.text = "Currently Connected to Server as Client.\nMultiplayer ID : " + str(multiplayer.multiplayer_peer.get_unique_id())

		elif connection_status == multiplayer.multiplayer_peer.ConnectionStatus.CONNECTION_DISCONNECTED:
			info_label.text = "Currently Disconnected."
		elif connection_status == multiplayer.multiplayer_peer.ConnectionStatus.CONNECTION_CONNECTING:
			info_label.text = "Currently Connecting..."
		else:
			info_label.text = "No status."
		info_label.text += "\nIs Server or Client ? : " + ("Server (Host)" if multiplayer.is_server() else "Client")
		var cur_player_info : Multiplayer_Info = get_node_or_null("../Spawner/"+str(get_multiplayer_authority())+"/Info")
		if cur_player_info:
			info_label.text += "\nUsername : " + cur_player_info.username
		
func update_player_list():
	for child in player_list.get_child_count():
		player_list.get_child(child).queue_free()
	for peer_id in multiplayer.get_peers():
		rpc_id(peer_id,"get_username",peer_id)