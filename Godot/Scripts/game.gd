extends Node3D

@onready var choosecube : OptionBlocks = $"ChooseCube"
@onready var label : Label3D = $"ChooseCube/SoftBody3D/Label3D"
@export var transition_speed_multiplier = 1.0
@onready var label_change_effect_timer = Timer.new()
var transition_direction = 1
var transition_time = 0.07



class RPG_System:
	pass

func changed_block(_curent_index: int, direction : int):
	label_change_effect_timer.start(transition_time)
	transition_direction = direction
	label.position.y = transition_time * direction
	label.modulate.a = 0
	label.text = choosecube.get_choose_cube_name()
	#label.text = BLOCKS_NAMES[-_curent_index % choosecube.blocks_nb]

# Called when the node enters the scene tree for the first time.
func _ready():
	label_change_effect_timer.autostart = false
	label_change_effect_timer.one_shot = true
	self.add_child(label_change_effect_timer)
	choosecube.change_block.connect(changed_block)

	var error = init_discordrpc()
	#DiscordRPC.run_callbacks()
	await get_tree().create_timer(10).timeout
	
	if not error:
		#DiscordRPC.debug()
		pass
	else:
		push_error("DiscordRPC didn't launch Discord : ", error_string(error))


func init_discordrpc():
	#if not DiscordRPC.get_is_discord_working():
		#return ERR_CANT_CONNECT
#
	#DiscordRPC.app_id = 1099618430065324082  # Application ID
	#DiscordRPC.details = "Main Scene - Combat System"
	#DiscordRPC.state = "Playtesting"
	#DiscordRPC.large_image = "image" # Image key from "Art Assets"
	#DiscordRPC.large_image_text = "Mario & Luigi : Hotel Mania"
	#DiscordRPC.small_image = "texture_03" # Image key from "Art Assets"
	#DiscordRPC.small_image_text = "Debuging - \"" + String(get_tree().current_scene.name) + "\""
#
	#DiscordRPC.start_timestamp = int(Time.get_unix_time_from_system()) # "02:46 elapsed"
	#DiscordRPC.end_timestamp = int(Time.get_unix_time_from_system()) + 3600 # +1 hour in unix time / "01:00:00 remaining"
	#DiscordRPC.refresh() # Always refresh after changing the values!

	return OK


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if (label_change_effect_timer.time_left):
		label.position.y = label_change_effect_timer.time_left * transition_direction
		label.modulate.a = (transition_time - label_change_effect_timer.time_left)/transition_time*5
	else:
		label.position.y = 0.0
		label.modulate.a = 1.0


