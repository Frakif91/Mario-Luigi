extends Control

var loaded_avatars : Dictionary

@export var persona_status_colors : Dictionary = {
	"Offline" : Color(0,0,0,1),
	"Busy" :    Color(0,0,0,1),
	"Away" :    Color(0,0,0,1),
	"Online" :  Color(0,0,0,1),
	"Playing" : Color(0,0,0,1)
}

@export_node_path("TextureRect") var user_avatar_np : NodePath
@export_node_path("Label") var user_name_np : NodePath
@export_node_path("ItemList") var user_friend_list_np : NodePath
@export_node_path("Label") var steam_info_np : NodePath

@onready var user_avatar : TextureRect = get_node(user_avatar_np)
@onready var user_name : Label = get_node(user_name_np)
@onready var user_friend_list : ItemList = get_node(user_friend_list_np) 
@onready var steam_info : Label = get_node(steam_info_np)

func _ready():
	if Steam.isSteamRunning():
		if Steam.getAppID() == 0:
			var steam_init = Steam.steamInit(true,480)
			steam_info.text = steam_init.get("verbal","---")
			print(steam_init)
		steam_initialized()
	else:
		steam_info.text = "Steam is OFF, it's maybe missing or not compatible with this game"


func steam_initialized():
	print("Steamworks finally works !")
	print(Steam.getAppID()," <-> ",Steam.getSteamID())
	var userID = Steam.getSteamID()
	var user_namev = Steam.getFriendPersonaName(userID)
	
	user_name.text = user_namev

	print("Ready to get avatar")
	Steam.avatar_loaded.connect(steam_user_avatar_loaded)
	#Steam.getPlayerAvatar(Steam.AVATAR_LARGE,userID) # Request steam to load image data of user
	user_avatar.texture = await await_avatar(userID) 

	await Globals.wait(0.5)

	user_friend_list.clear()
	for friend in Steam.getUserSteamFriends(): #return friends in a Dictionary
		friend = (friend as Dictionary) # Visual Code Studio definition only (for autocomplete)
		var friend_name = friend.get("name","none")
		var friend_status = friend.get("status",-1)
		var friend_id = friend.get("id",0)
		var friend_avatar = await await_avatar(friend_id)
		var friend_bg_color : Color
		match friend_status:
			Steam.PERSONA_STATE_ONLINE:
				friend_bg_color = persona_status_colors["Online"]
			Steam.PERSONA_STATE_AWAY:
				friend_bg_color = persona_status_colors["Away"]
			Steam.PERSONA_STATE_BUSY:
				friend_bg_color = persona_status_colors["Busy"]
			Steam.PERSONA_STATE_LOOKING_TO_PLAY:
				friend_bg_color = persona_status_colors["Playing"]
			_:
				friend_bg_color = persona_status_colors["Offline"]

		var item_id = user_friend_list.add_item(friend_name, friend_avatar)
		user_friend_list.set_item_disabled(item_id, not(friend_status as bool))
		user_friend_list.set_item_custom_bg_color(item_id, friend_bg_color)

		
func steam_user_avatar_loaded(id, icon_size, buffer : PackedByteArray):
	var avatarImage = Image.create_from_data(icon_size, icon_size, false, Image.FORMAT_RGBA8, buffer)

	var texture = ImageTexture.create_from_image(avatarImage)
	loaded_avatars.merge({id : texture},true)

func get_steam_avatar(id) -> ImageTexture:
	return loaded_avatars.get(id,preload("res://icon.svg"))

func await_avatar(id) -> ImageTexture:
	Steam.getPlayerAvatar(Steam.AVATAR_MEDIUM,id)
	await Steam.avatar_loaded
	return get_steam_avatar(id)

func _on_button_exit_pressed() -> void:
	Transitions.start_loading("res://Godot/Scene/title.tscn",Transitions.TransitionType.FILL,get_tree())
