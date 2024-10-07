extends Control

signal update_progression(progress : float)

signal start_loading

signal end_loading

var progression = 0.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	start_loading.connect(func(): $"Animation".play(&"Loading"))
	end_loading.connect(func(): $"Animation".play_backwards(&"Loading"))
	update_progression.connect( func(prog : float): $"Label".text = str(roundi(prog*100)) + "%")

func set_custom_load_message(str_msg : String):
	$"Label".text = str_msg