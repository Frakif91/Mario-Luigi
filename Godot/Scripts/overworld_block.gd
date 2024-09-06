class_name OW_Block extends StaticBody3D

signal block_hit()

var block_has_been_hit = false

@onready var audio_player : AudioStreamPlayer = AudioStreamPlayer.new()
@onready var question_block = $"Question Block"
@onready var used_cube = $"Used Block 1"
var og_cube_pos

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	og_cube_pos = used_cube.position
	add_child(audio_player)
	block_hit.connect(block_got_hit)
	question_block.show()
	used_cube.hide()

func block_got_hit():
	if not block_has_been_hit:
		block_has_been_hit = true
		audio_player.stream = load("res://Assets/SFX/WU_SE_OBJ_GET_COIN.wav")
		audio_player.play()
	else:
		audio_player.stream = load("res://Assets/Sound/SE_BTL_BLOCK_HIT.wav")
		audio_player.play()

	question_block.hide()
	used_cube.show()
	used_cube.position += Vector3(0,0.3,0)

func _process(delta: float) -> void:
	used_cube.position = lerp(used_cube.position,og_cube_pos,delta*5)